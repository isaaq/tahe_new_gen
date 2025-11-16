# frozen_string_literal: true

require 'singleton'

# RelationRegistry - 关联关系注册表
# 支持多级缓存和优先级策略（kr:col > 模型定义 > 自动发现）
class RelationRegistry
  include Singleton
  
  CACHE_COLLECTION = 'sys_relation_cache'
  CACHE_TTL = 7 * 24 * 3600  # 7天过期
  
  def initialize
    @memory_cache = {}        # 一级缓存：内存
    @model_relations = {}     # 从模型扫描的关联
    @collection_cache = {}    # 集合名缓存
    ensure_indexes!
  end
  
  # 启动时扫描模型定义（可选）
  def self.auto_discover_models!
    instance.send(:scan_model_definitions)
  end
  
  # 核心方法：解析关联配置（支持优先级策略）
  def self.resolve(relation_name, foreign_key, source_collection, explicit_config = nil)
    instance.send(:resolve_with_priority, relation_name, foreign_key, source_collection, explicit_config)
  end
  
  # 管理接口：查看所有缓存
  def self.list_all_cached
    M[CACHE_COLLECTION].find.to_a
  rescue => e
    puts "⚠️  读取缓存失败: #{e.message}"
    []
  end
  
  # 管理接口：清空缓存
  def self.clear_all_cache!
    M[CACHE_COLLECTION].delete_many({})
    instance.instance_variable_set(:@memory_cache, {})
    puts "✅ 已清空所有关联缓存"
  rescue => e
    puts "⚠️  清空缓存失败: #{e.message}"
  end
  
  # 管理接口：清理过期缓存
  def self.cleanup_expired!
    result = M[CACHE_COLLECTION].delete_many({ ttl: { '$lt': Time.now } })
    puts "✅ 清理了 #{result.deleted_count} 条过期缓存"
  rescue => e
    puts "⚠️  清理过期缓存失败: #{e.message}"
  end
  
  private
  
  def resolve_with_priority(relation_name, foreign_key, source_collection, explicit_config)
    cache_key = build_cache_key(source_collection, relation_name)
    
    # 1. 查询三级缓存
    cached = get_cached_config(cache_key)
    return cached if cached
    
    # 2. 优先级策略
    config = nil
    
    # 优先级1: kr:col 显式配置（用户意图最高）
    if explicit_config && explicit_config[:collection]
      config = explicit_config.merge(
        foreign_key: foreign_key,
        type: infer_relation_type(foreign_key),
        source: :explicit
      )
    end
    
    # 优先级2: 从模型定义获取
    unless config
      model_config = get_from_model(source_collection, relation_name)
      config = model_config if model_config
    end
    
    # 优先级3: 运行时自动发现
    unless config
      config = auto_discover(relation_name, foreign_key, source_collection)
    end
    
    # 3. 验证并缓存
    validate_and_cache(cache_key, config)
    
    config
  end
  
  # ========== 缓存管理 ==========
  
  def get_cached_config(cache_key)
    # 1. 内存缓存（最快）
    return @memory_cache[cache_key] if @memory_cache[cache_key]
    
    # 2. MongoDB 缓存（持久化）
    cached = load_from_mongo(cache_key)
    if cached
      @memory_cache[cache_key] = cached  # 回填内存
      return cached
    end
    
    nil
  end
  
  def load_from_mongo(cache_key)
    return nil unless defined?(M)
    
    doc = M[CACHE_COLLECTION].query({ cache_key: cache_key }).first
    return nil unless doc
    
    # 检查是否过期
    return nil if doc['ttl'] && doc['ttl'] < Time.now
    
    {
      collection: doc['collection'],
      foreign_key: doc['foreign_key'],
      type: doc['type']&.to_sym,
      source: doc['source']&.to_sym,
      cached_at: doc['cached_at']
    }
  rescue => e
    puts "⚠️  从MongoDB加载缓存失败: #{e.message}" if dev?
    nil
  end
  
  def validate_and_cache(cache_key, config)
    # 检查是否与已缓存的配置冲突
    if @memory_cache[cache_key]
      cached = @memory_cache[cache_key]
      if cached[:collection] != config[:collection]
        warn_inconsistency(cache_key, cached, config)
        # 用户显式配置优先
        config = cached if cached[:source] == :explicit
      end
    end
    
    # 保存到内存
    @memory_cache[cache_key] = config
    
    # 保存到 MongoDB（异步，不阻塞）
    save_to_mongo_async(cache_key, config)
    
    config
  end
  
  def save_to_mongo_async(cache_key, config)
    return unless defined?(M)
    
    # 可以用线程池或后台任务
    Thread.new do
      begin
        M[CACHE_COLLECTION].upsert(
          { cache_key: cache_key },
          {
            cache_key: cache_key,
            collection: config[:collection],
            foreign_key: config[:foreign_key],
            type: config[:type].to_s,
            source: config[:source].to_s,
            cached_at: Time.now,
            ttl: Time.now + CACHE_TTL
          }
        )
        
        puts "💾 已缓存关联: #{cache_key} -> #{config[:collection]}" if dev?
      rescue => e
        puts "⚠️  保存缓存失败: #{e.message}" if dev?
      end
    end
  end
  
  # ========== 模型扫描 ==========
  
  def scan_model_definitions
    scanned_count = 0
    
    ObjectSpace.each_object(Class)
      .select { |c| c.respond_to?('表名'.to_sym) }
      .each do |model_class|
        
      collection_name = model_class.send('表名'.to_sym)
      
      model_class.send('构'.to_sym)&.each do |field_def|
        next unless field_def.keys.first == :Link
        
        field_config = field_def[:Link]
        field_name = field_config[0]
        link_config = field_config[2] || {}
        
        if link_config[:link_to]
          relation_name = field_name.to_s.sub(/_id$/, '')
          
          begin
            target_model = Object.const_get(link_config[:link_to])
            target_collection = target_model.send('表名'.to_sym)
            
            model_key = "#{collection_name}.#{relation_name}"
            @model_relations[model_key] = {
              collection: target_collection,
              foreign_key: field_name,
              type: :belongs_to,
              source: :model
            }
            
            scanned_count += 1
            puts "📚 从模型发现: #{model_key} -> #{target_collection}" if dev?
          rescue => e
            # 模型类不存在，跳过
            puts "⚠️  扫描模型失败 #{link_config[:link_to]}: #{e.message}" if dev?
          end
        end
      end
    end
    
    puts "✅ 模型扫描完成，发现 #{scanned_count} 个关联" if dev?
  end
  
  def get_from_model(source_collection, relation_name)
    model_key = "#{source_collection}.#{relation_name}"
    @model_relations[model_key]
  end
  
  # ========== 自动发现 ==========
  
  def auto_discover(relation_name, foreign_key, source_collection)
    target_collection = discover_collection(relation_name)
    
    {
      collection: target_collection,
      foreign_key: foreign_key,
      type: infer_relation_type(foreign_key),
      source: :discovered
    }
  end
  
  def discover_collection(relation_name)
    # 从缓存返回
    return @collection_cache[relation_name] if @collection_cache[relation_name]
    
    # 1. 先检查特殊映射（配置化）
    special_mapping = naming_config['special_mappings']&.[](relation_name.to_s)
    if special_mapping
      @collection_cache[relation_name] = special_mapping
      puts "🎯 特殊映射: #{relation_name} -> #{special_mapping}" if dev?
      return special_mapping
    end
    
    # 2. 使用配置的命名模式（替代硬编码）
    patterns = naming_config['collection_naming_patterns'].map do |pattern|
      pattern.gsub('{relation_name}', relation_name.to_s)
    end
    
    # 3. 查询 MongoDB 验证集合是否存在（如果启用）
    if naming_config['enable_auto_discovery']
      found = patterns.find { |p| collection_exists?(p) }
      result = found || patterns.first  # 使用第一个模式作为默认值
      puts "🔍 自动发现: #{relation_name} -> #{result}" if found && dev?
    else
      result = patterns.first
      puts "📋 模式匹配: #{relation_name} -> #{result}" if dev?
    end
    
    # 缓存结果
    @collection_cache[relation_name] = result
    
    result
  end
  
  def naming_config
    @naming_config ||= load_naming_config
  end
  
  def load_naming_config
    require 'yaml'
    config_path = File.join(__dir__, 'naming_convention_config.yml')
    if File.exist?(config_path)
      YAML.load_file(config_path)
    else
      # 默认配置（防御性编程）
      {
        'collection_naming_patterns' => [
          "b_{relation_name}s",
          "b_{relation_name}",
          "org_{relation_name}s",
          "sys_{relation_name}s",
          "{relation_name}s"
        ],
        'special_mappings' => {},
        'enable_auto_discovery' => true
      }
    end
  rescue => e
    puts "⚠️  加载命名配置失败: #{e.message}" if dev?
    # 返回默认配置
    {
      'collection_naming_patterns' => ["b_{relation_name}s"],
      'special_mappings' => {},
      'enable_auto_discovery' => true
    }
  end
  
  def collection_exists?(collection_name)
    return false unless defined?(M)
    
    M[collection_name.to_sym].query({}).limit(1).count >= 0
  rescue
    false
  end
  
  # ========== 辅助方法 ==========
  
  def infer_relation_type(foreign_key)
    # package_id -> belongs_to
    # role_ids -> many_to_many (数组)
    foreign_key.to_s.end_with?('_ids') ? :many_to_many : :belongs_to
  end
  
  def build_cache_key(source, relation)
    source ? "#{source}.#{relation}" : relation.to_s
  end
  
  def warn_inconsistency(cache_key, cached, new_config)
    return unless dev?
    
    puts "⚠️  关联配置冲突: #{cache_key}"
    puts "   已缓存: #{cached[:collection]} (来源: #{cached[:source]})"
    puts "   新配置: #{new_config[:collection]} (来源: #{new_config[:source]})"
    puts "   使用: #{cached[:source] == :explicit ? '已缓存配置' : '新配置'}"
  end
  
  def ensure_indexes!
    return unless defined?(M)
    
    begin
      # 创建唯一索引
      M[CACHE_COLLECTION].indexes.create_one(
        { cache_key: 1 }, 
        { unique: true }
      )
      
      # 创建 TTL 索引（自动清理过期数据）
      M[CACHE_COLLECTION].indexes.create_one(
        { ttl: 1 }, 
        { expireAfterSeconds: 0 }
      )
      
      puts "✅ 关联缓存索引已创建" if dev?
    rescue => e
      # 索引已存在或MongoDB未连接
      puts "⚠️  创建索引失败（可能已存在）: #{e.message}" if dev?
    end
  end
  
  def dev?
    ENV['RACK_ENV'] != 'production'
  end
end
