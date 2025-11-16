# frozen_string_literal: true

# MongoQueryEngine - MongoDB通用查询引擎
# 支持透明的关联查询和智能Filter
class MongoQueryEngine
  # 执行查询协议
  def self.execute(protocol, context = {})
    # 1. 智能处理 filter
    filter = normalize_filter(protocol['filter'] || {})
    
    # 2. 查询主集合
    records = query_main_collection(
      protocol['collection'],
      filter,
      protocol['page'] || 1,
      protocol['limit'] || 20,
      protocol['sort']
    )
    
    # 3. 处理关联（批量查询，避免N+1）
    if protocol['expand']&.any?
      records = expand_relations(records, protocol['expand'])
    end
    
    # 4. 返回结果
    {
      data: records,
      count: count_total(protocol['collection'], filter)
    }
  end
  
  private
  
  # 处理关联查询
  def self.expand_relations(records, expand_configs)
    return records unless expand_configs&.any?
    
    expand_configs.each do |config|
      relation_name = config['relation']
      target_collection = config['collection']
      foreign_key = config['foreign_key']
      display_field = config['display_field']
      result_field = config['result_field']
      
      # 收集所有需要查询的外键值
      foreign_key_values = records.map { |record| record[foreign_key] }.compact.uniq
      
      if foreign_key_values.any?
        # 批量查询关联数据
        related_docs = batch_query_related_docs(target_collection, foreign_key_values, '_id')
        
        # 构建映射表
        mapping = related_docs.index_by { |doc| doc['_id'] }
        
        # 为每条记录添加关联数据
        records.each do |record|
          foreign_value = record[foreign_key]
          if foreign_value && mapping[foreign_value]
            record[result_field] = mapping[foreign_value][display_field]
          end
        end
      end
    end
    
    records
  end
  
  # 批量查询关联文档
  def self.batch_query_related_docs(collection_name, foreign_keys, target_key)
    return [] unless defined?(M)
    collection = M[collection_name.to_sym]
    
    # 处理不同类型的ID
    normalized_keys = normalize_foreign_keys(foreign_keys)
    
    # 批量查询
    query_field = target_key == '_id' ? :_id : target_key.to_sym
    collection.query({ query_field => { '$in': normalized_keys } }).to_a
  rescue => e
    puts "⚠️  批量查询关联集合失败 #{collection_name}: #{e.message}"
    []
  end
  
  # 规范化外键值
  def self.normalize_foreign_keys(foreign_keys)
    foreign_keys.map do |key|
      # 如果是字符串，尝试转换为ObjectId
      if key.is_a?(String) && key.match?(/^[0-9a-fA-F]{24}$/)
        BSON::ObjectId.from_string(key)
      else
        key
      end
    end
  end
  
  # 查询主集合
  def self.query_main_collection(collection_name, filter, page, limit, sort_config = nil)
    collection = M[collection_name.to_sym]
    
    # 构建查询
    query = collection.query(filter)
    
    # 应用排序
    if sort_config && !sort_config.empty?
      query = query.sort(sort_config)
    else
      # 默认按创建时间倒序
      query = query.sort({ create_time: -1 }) rescue query
    end
    
    # 应用分页
    skip = (page - 1) * limit
    query.skip(skip).limit(limit).to_a
  rescue => e
    puts "⚠️  查询主集合失败 #{collection_name}: #{e.message}"
    []
  end
  
  # 批量加载关联数据（核心！避免N+1问题）
  def self.expand_relations(records, expands)
    return records if records.empty?
    
    expands.each do |expand|
      begin
        # 1. 提取所有外键值
        foreign_keys = extract_foreign_keys(records, expand['foreign_key'])
        next if foreign_keys.empty?
        
        # 2. 批量查询关联集合
        related_records = batch_query_related(
          expand['collection'],
          foreign_keys,
          expand['target_key'] || '_id'
        )
        
        # 3. 构建索引（快速查找）
        related_map = build_related_map(related_records, expand['target_key'] || '_id')
        
        # 4. 合并数据到主记录
        merge_related_data(records, related_map, expand)
      rescue => e
        puts "⚠️  处理关联 #{expand['relation']} 失败: #{e.message}"
        # 不影响主流程，继续处理其他关联
      end
    end
    
    records
  end
  
  def self.extract_foreign_keys(records, foreign_key)
    records.map { |r| r[foreign_key] || r[foreign_key.to_sym] }
           .compact
           .uniq
  end
  
  def self.batch_query_related(collection_name, foreign_keys, target_key)
    collection = M[collection_name.to_sym]
    
    # 处理不同类型的ID
    normalized_keys = normalize_foreign_keys(foreign_keys)
    
    # 批量查询
    query_field = target_key == '_id' ? :_id : target_key.to_sym
    collection.query({ query_field => { '$in': normalized_keys } }).to_a
  rescue => e
    puts "⚠️  批量查询关联集合失败 #{collection_name}: #{e.message}"
    []
  end
  
  def self.normalize_foreign_keys(keys)
    keys.map do |key|
      # 尝试转换为 ObjectId
      begin
        if key.is_a?(String) && key =~ /^[0-9a-f]{24}$/i
          BSON::ObjectId(key)
        else
          key
        end
      rescue
        key
      end
    end
  end
  
  def self.build_related_map(related_records, target_key)
    key_field = target_key == '_id' ? '_id' : target_key
    
    related_records.each_with_object({}) do |record, map|
      key_value = record[key_field] || record[key_field.to_sym]
      map[key_value.to_s] = record if key_value
    end
  end
  
  def self.merge_related_data(records, related_map, expand)
    foreign_key = expand['foreign_key']
    display_field = expand['display_field']
    result_field = expand['result_field']
    
    records.each do |record|
      fk_value = record[foreign_key] || record[foreign_key.to_sym]
      next unless fk_value
      
      # 查找关联数据
      related = related_map[fk_value.to_s]
      
      if related
        # 添加关联字段到主记录
        display_value = related[display_field] || related[display_field.to_sym]
        record[result_field] = display_value
      end
    end
  end
  
  # 智能处理 filter（支持老系统语法）
  def self.normalize_filter(filter)
    return {} unless filter
    
    # 递归处理 filter，智能类型转换
    filter.each_with_object({}) do |(key, value), result|
      case value
      when Hash
        # 递归处理嵌套对象（如 $gte, $lte 等）
        result[key.to_sym] = normalize_filter(value)
      when String
        # 字符串智能转换
        result[key.to_sym] = normalize_string_value(value)
      else
        result[key.to_sym] = value
      end
    end
  end
  
  def self.normalize_string_value(value)
    # ObjectId
    begin
      return BSON::ObjectId(value) if value =~ /^[0-9a-f]{24}$/i
    rescue
      # 不是合法的 ObjectId，继续
    end
    
    # 数字
    return value.to_i if value =~ /^\d+$/
    
    # 布尔
    return true if value == 'true'
    return false if value == 'false'
    
    # 默认字符串
    value
  end
  
  def self.count_total(collection_name, filter)
    collection = M[collection_name.to_sym]
    collection.count(filter)
  rescue => e
    puts "⚠️  统计总数失败 #{collection_name}: #{e.message}"
    0
  end
end
