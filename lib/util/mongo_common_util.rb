require_relative 'db_mongo'

module MongoCommonUtil
  attr_accessor :load_path, :user

  def common_data
    {
      _create_time: Time.now,
      _update_time: Time.now,
      _enabled: true
    }
  end

  def load_model(file = nil)
    @db = DBMongo.new if @db.nil?
    if file.nil?
    else
      txt = File.read(file)
      lines = txt.split("\n")
      lines.each do |l|
        parse(l)
      end
    end
    
    # 加载完模型后创建全局搜索索引
    create_global_search_index if @db && @db.model
    
    self
  end
  
  # 为标记了is_global_search的字段创建全文索引
  def create_global_search_index
    return if @db.nil? || @db.model.nil? || !@db.model.respond_to?(:_fields)
    
    # 获取所有标记为全局搜索的字段
    global_search_fields = @db.model._fields.select { |f| f.is_a?(Hash) && f[:is_global_search] }
    return if global_search_fields.empty?
    
    begin
      # 创建索引定义
      index_fields = {}
      global_search_fields.each do |field|
        field_name = field[:name] || field['name']
        next if field_name.nil?
        index_fields[field_name] = "text"
      end
      
      # 如果有需要索引的字段，创建文本索引
      if index_fields.any?
        puts "为表 #{@db.table} 创建全局搜索索引: #{index_fields.keys.join(', ')}"
        # 检查索引是否已存在，如果存在则不重新创建
        existing_indexes = @db.db[@db.table].indexes.list.to_a
        index_exists = existing_indexes.any? { |idx| idx["name"] == "global_search_index" }
        
        unless index_exists
          @db.db[@db.table].indexes.create_one(index_fields, { name: "global_search_index" })
          puts "全局搜索索引创建成功"
        else
          puts "全局搜索索引已存在，跳过创建"
        end
      end
    rescue => e
      puts "创建全局搜索索引失败: #{e.message}"
    end
  end

  def [](key)
    @db = DBMongo.new if @db.nil?
    # TODO: 从.m文件中读取 目前读test目录需要修改

    # TODO: 读取系统模型
    load_sys_models
    Global.instance._user_models ||= []
    # TODO: 缓存
    unless @load_path.nil?
      Dir["#{@load_path}/*.m"].each do |mfile|
        model = parse_file_model(mfile)
        Global.instance._user_models << model if !model.nil? && !Global.instance._user_models.include?(model)
      end
    else
      # TODO: 读取用户模型 默认读取哪里的 从数据库 从C配置文件 从某默认目录
      
    end

    # path = "./test/data/dsl/model/#{key}.m"
    # Global.instance._user_models.find {|f| f}
    models = ((Global.instance._sys_models || []) + Global.instance._user_models).flatten(1)
    found = models.find { |f| f._name.to_s == key.to_s }
    if found.nil?
      table(key)
    else
      # found.public_methods(false).each do |m|
      #   next unless m.name[0] == '_'

      #   parse "#{m.name} #{found.send m.name}"
      # end
      table(found._table)
    end
    @db.model = found
    self
  end

  def db
    @db.db
  end
  def change_db(db_name, opts = {})
    @db = DBMongo.new(opts)
    @db.db = @db.db.use(db_name)
    self
  end

  def query(query_hash = {}, opts = {})
    # 确保在查询前创建索引
    create_global_search_index if query_hash.has_key?(:_global_search_str)
    
    # __p "[查询前] 原始条件: #{query_hash.inspect}"
    mongo_parse_query!(query_hash)
    # __p "[查询后] 处理后条件: #{query_hash.inspect}"
    # __p "[查询表名] #{@db.table}"
    
    qry = @db.db[@db.table].find(query_hash)
    qry = qry.projection(opts[:show]) unless opts[:show].nil?
    qry = qry.sort(opts[:sort]) unless opts[:sort].nil?
    @db.db.close
    qry.model = @db.model
    
    # 扩展MongoDB的Cursor类型，在to_a方法中处理自定义字段
    mongo_util = self
    original_to_a = qry.method(:to_a)
    qry.define_singleton_method(:to_a) do
      results = original_to_a.call
      # __p "[查询结果] 结果数量: #{results.size}, 第一条数据: #{results.first.inspect if results.any?}"
      results.each do |item|
        mongo_util.process_custom_fields_from_db(item) if item.is_a?(Hash)
      end
      results
    end
    
    qry
  end

  def del(query_hash = {})
    del_data = @db.db[@db.table].find(query_hash).to_a
    r = @db.db[@db.table].delete_one(query_hash)
    # 垃圾箱
    Common::C[:audit_level] ||= 2
    add_to_recyc(del_data, 'del') if Common::C[:audit_level] != 0
    @db.db.close
    r
  end

  def del_many(query_hash = {})
    del_data = @db.db[@db.table].find(query_hash).to_a
    r = @db.db[@db.table].delete_many(query_hash)
    # 垃圾箱
    Common::C[:audit_level] ||= 2
    add_to_recyc(del_data, 'del_many') if Common::C[:audit_level] != 0
    @db.db.close
    r
  end

  def add(data = {}, _opts = {})
    # 处理自定义字段类型
    process_custom_fields_for_storage(data)
    data.merge!(common_data)
    Common::C[:audit_level] ||= 2
    add_to_recyc(data, 'add') if Common::C[:audit_level] >= 3
    r = @db.db[@db.table].insert_one(data)
    @db.db.close
    r
  end

  def update(query_hash = {}, data = {}, _opts = {})
    # 处理自定义字段类型
    process_custom_fields_for_storage(data)
    common_update_data = {
      _update_time: Time.now
    }
    # 确保使用$set操作符
    update_doc = data.key?('$set') || data.key?(:$set) ? data : { '$set' => data.merge(common_update_data) }
    r = @db.db[@db.table].find_one_and_update(query_hash, update_doc)
    Common::C[:audit_level] ||= 2
    if Common::C[:audit_level] >= 2
      data = @db.db[@db.table].find(query_hash).to_a
      add_to_recyc(data, 'update')
    end
    @db.db.close
    r
  end

  def update_many(query_hash = {}, data = {}, _opts = {})
    # 处理自定义字段类型
    process_custom_fields_for_storage(data)
    common_update_data = {
      _update_time: Time.now
    }
    data.merge!(common_update_data)
    r = @db.db[@db.table].update_many(query_hash, data)
    Common::C[:audit_level] ||= 2
    if Common::C[:audit_level] >= 2
      data = @db.db[@db.table].find(query_hash).to_a
      add_to_recyc(data, 'update_many')
    end
    @db.db.close
    r
  end

  # def method_missing(m, *_args)
  #   __p "missing #{m} #{_args}"
  # end

  def gen_sample_ui_code; end

  private

  def parse_file_model(path)
    return unless File.exist?(path)

    txt = File.read(path)
    bm = BaseModel.new
    bm.extend SysModelCommon

    lines = txt.split("\n")
    lines.each do |l|
      parse_code_to_clazz(l, bm)
    end
    # Global.instance._user_models ||= []
    # Global.instance._user_models << bm
    bm
  end

  def add_to_recyc(del_data, type)
    data = { table: @db.table, data: del_data, type: type }
    data.merge!(common_data)
    @db.db[:recyc].insert_one(data)
  end

  def extends(_params)
    nil unless self.class.is_a?(BaseModel)
  end

  def table(params)
    @db.table = params
  end

  def table_alias(params)
    @db.table_alias = params
  end

  def process_type(clazz)
    bs = clazz.new
    bs.build
  end

  def parse_code_to_clazz(line, clazz)
    return nil if line.match(%r{^// .+?})

    line.strip!
    parsed_code = line.split(' ')
    return unless parsed_code.length > 0

    sym = parsed_code[0].to_sym
    cmd = { '↑': 'extends', '表': '_table', '名': '_name', '->': '_fk' }
    func = cmd[sym]&.to_sym || sym.to_s.gsub('_', '').to_sym
    begin
      clazz.send(func, *parsed_code[1].split(','))
    rescue Exception => e
      __p e
    end
  end

  def parse(code)
    return nil if code.match(%r{^// .+?})

    code.strip!
    parsed_code = code.split(' ')
    return unless parsed_code.length > 0

    sym = parsed_code[0].to_sym
    cmd = { '↑': 'extends', '表': 'table', '名': 'table_alias' }
    type_list = ObjectSpace.each_object(Class).select { |klass| klass < BaseType }
    func = cmd[sym]&.to_sym || sym.to_s.gsub('_', '').to_sym
    if func.nil?
      type_map = type_list.each_with_object({}) do |i, t|
        t[i._name] = i
      end
      process_type(type_map[sym]) if !type_map.nil? && !type_map[sym].nil?
    elsif private_methods.include?(func)
      send(func, parsed_code[1])
    end
  end

  class MongoResult
    def self.get_ret(db, qry)
      result = qry.to_a
      db.db.close
      __p db.db.closed?
      result
    end
  end

  def filter_role(qry)
    # TODO 得处理角色继承关系
    return true if @user[:role] == 'admin'  # 管理员拥有全部权限
    meta = qry[:_meta] || {}
    # 按优先级检查权限
    meta[:created_by] == @user[:_id] ||            # 是否是创建者
    meta[:access_rules][:public] ||               # 是否公开
    (meta[:access_rules][:department_visible] &&  # 是否本部门可见
      @user[:department_id] == meta[:department_id]) ||
    meta[:access_rules][:allowed_users].include?(@user[:_id]) ||  # 是否在指定用户中
    (meta[:access_rules][:allowed_groups] & @user[:groups]).any?  # 是否在指定组中
  end

  # @param [Hash] qry
  def mongo_parse_query!(qry)
    return if qry.nil?
    
    # 全局搜索
    if qry.has_key?(:_global_search_str) && !qry[:_global_search_str].nil?
      search_text = qry.delete(:_global_search_str)
      
      # 如果有模型定义，则使用模型中标记为全局搜索的字段
      if @db && @db.model && @db.model.respond_to?(:_fields)
        # 获取所有标记为全局搜索的字段
        global_search_fields = @db.model._fields.select { |f| f.is_a?(Hash) && f[:is_global_search] }
        
        if global_search_fields && !global_search_fields.empty?
          # 构建 $or 查询，搜索每个标记为全局搜索的字段
          or_conditions = global_search_fields.map do |field|
            field_name = field[:name] || field['name']
            next if field_name.nil?
            # 使用正则表达式进行不区分大小写的搜索
            { field_name => { '$regex' => search_text, '$options' => 'i' } }
          end.compact
          
          # 添加到查询中
          if or_conditions.any?
            qry['$or'] = or_conditions
          end
        else
          # 如果没有找到标记的字段，则使用正则表达式搜索name字段（通常存在）
          # 避免使用$text操作符，因为它需要文本索引
          qry['name'] = { '$regex' => search_text, '$options' => 'i' }
        end
      else
        # 没有模型定义时，使用name字段的正则表达式搜索
        qry['name'] = { '$regex' => search_text, '$options' => 'i' }
      end
    end
    
    # 角色权限
    if Common::C[:auto_role_query] == 1
      unless @user.nil? || @user['roles'].nil?
        filter_role(qry)
        qry.merge!({ '_meta.roles': { '$in': @user['roles'] } })
      end
    end
    
    # 处理自定义字段类型查询
    # 将原始查询替换为处理后的查询
    processed_query = process_custom_field_queries(qry)
    
    # 清空原始查询并合并处理后的查询
    qry.clear
    qry.merge!(processed_query)
    
    # 模型的额外属性
    # __p @db.model._fk
  end
  
  # 处理自定义字段类型查询
  def process_custom_field_queries(original_query)
    return original_query if original_query.nil?
    
    # 创建新的查询条件 - 避免在迭代中修改原始查询
    new_query = {}
    
    # 首先复制原始查询中的所有内容
    original_query.each do |k, v|
      # 标记这些特殊的查询条件
      if k.to_s.start_with?('$')
        new_query[k] = v
        next
      end
      
      # 尝试使用 FieldRegistry 处理自定义字段查询
      require_relative '../model/type/field_registry'
      query_result = FieldRegistry.process_query(k, v)
      
      if query_result
        # 如果查询被处理，直接使用处理后的结果
        if query_result.is_a?(Hash) && query_result.key?(k)
          # 如果返回的查询包含原字段名作为键，则使用该查询
          new_query[k] = query_result[k]
        elsif query_result.is_a?(Hash) && (query_result.key?("$and") || query_result.key?("$or"))
          # 如果是逐步查询，则简单使用该查询（替换原始查询）
          # 注意：这里我们假设 $and 和 $or 不会同时存在于新查询中
          return query_result
        else
          # 其他情况，将处理后的查询条件添加到新查询中
          new_query.merge!(query_result)
        end
        
        # 跳过下面的处理
        next
      end
      
      # 处理普通字段或其他情况
      new_query[k] = v
      
      # 递归处理嵌套查询
      if v.is_a?(Hash) && !v.empty?
        new_query[k] = process_custom_field_queries(v)
      end
      
      # 处理数组中的查询条件
      if v.is_a?(Array)
        new_query[k] = v.map do |item|
          item.is_a?(Hash) ? process_custom_field_queries(item) : item
        end
      end
    end
    
    # 返回新的查询条件
    return new_query
  end

  def load_sys_models
    './lib/model/sys'
    # MSysPage._table
    # p Dir.entries(path)
    # @_sys_models
  end

  class Mongo::Collection::View
    attr_accessor :model

    def to_all
      all = self.to_a # super.to_a
      all.each do |e|
        # 处理自定义字段类型
        process_custom_fields_from_db(e) if e.is_a?(Hash)
        
        @model&._fks&.each do |fk|
          fnd = Global.instance._user_models.find { |f| f._name == fk.name || f._table == fk.table }
          tbl_name = fnd._table
          e["fk_#{tbl_name}".to_sym]&.map! do |m|
            id = m.is_a?(Hash) ? m[:_id] || m[:id] : m
            Common::M[tbl_name.to_sym].query(_id: id&.to_objid).to_a[0]
          end
        end
      end
    end
  end
  
  # 处理存储前的自定义字段类型
  public
  def process_custom_fields_for_storage(data)
    return if data.nil?
    
    # 加载字段类型处理器
    begin
      require_relative '../model/type/field_registry'
    rescue LoadError => e
      puts "加载字段类型注册器失败: #{e.message}"
      return
    end
    
    # 处理数据中的每个字段
    data.each do |k, v|
      # 处理显式指定的类型
      if v.is_a?(Hash) && v[:_type]
        field_type = v[:_type]
        field_value = v[:value]
        
        begin
          # 特殊处理坐标字段
          if field_type == 'coordinate' && field_value.is_a?(Array) && field_value.size == 2
            require_relative '../model/type/custom/coordinate_field'
            field = CoordinateField.new
            field.value = field_value
            if field.valid?
              data[k] = field.to_db
              puts "处理显式坐标字段 #{k} 成功"
              next
            end
          end
          
          # 创建字段实例
          field = FieldRegistry.create_field(field_type)
          field.value = field_value
          
          # 如果字段有效，将其转换为数据库格式
          if field.respond_to?(:valid?) && field.valid?
            db_value = field.to_db
            if db_value
              data[k] = db_value
              puts "处理字段 #{k} (类型: #{field_type}) 成功"
            end
          end
        rescue => e
          puts "处理显式类型字段 #{k} (类型: #{field_type}) 错误: #{e.message}"
        end
        next
      end
      
      # 使用 FieldRegistry 检测坐标字段类型
      if v.is_a?(Array) && v.size == 2 && v.all? { |item| item.is_a?(Numeric) }
        # 检查是否是坐标数据
        field_type = FieldRegistry.detect_field_type(k, v)
        if field_type
          begin
            field = FieldRegistry.create_field(field_type)
            field.value = v
            if field.valid?
              data[k] = field.to_db
              puts "处理坐标字段 #{k} 成功"
              next
            end
          rescue => e
            puts "处理坐标字段 #{k} 错误: #{e.message}"
          end
        end
      end
      
      # 使用 FieldRegistry 检测字段类型
      field_type = FieldRegistry.detect_field_type(k, v)
      
      if field_type
        begin
          # 创建字段实例
          field = FieldRegistry.create_field(field_type)
          field.value = v
          
          # 如果字段有效，将其转换为数据库格式
          if field.respond_to?(:valid?) && field.valid?
            db_value = field.to_db
            if db_value
              data[k] = db_value
              puts "处理字段 #{k} (类型: #{field_type}) 成功"
            end
          end
        rescue => e
          puts "处理字段 #{k} (类型: #{field_type}) 错误: #{e.message}"
        end
      end
      
      # 递归处理嵌套字段
      if v.is_a?(Hash) && !v.empty?
        process_custom_fields_for_storage(v)
      elsif v.is_a?(Array)
        # 处理数组中的对象
        v.each_with_index do |item, index|
          if item.is_a?(Hash) && !item.empty?
            process_custom_fields_for_storage(item)
          end
        end
      end
    end
  end
  
  # 处理查询结果中的自定义字段类型
  public
  def process_custom_fields_from_db(data)
    return if data.nil?
    
    # 加载字段类型处理器
    begin
      require_relative '../model/type/field_registry'
    rescue LoadError => e
      puts "加载字段类型注册器失败: #{e.message}"
      return
    end
    
    # 递归处理数据
    process_data_recursively(data)
  end
  
  # 递归处理数据中的自定义字段
  private
  def process_data_recursively(data)
    return if data.nil?
    
    if data.is_a?(Hash)
      # 处理哈希表
      data.each do |k, v|
        # 先处理显式指定类型的字段
        if v.is_a?(Hash) && v[:_type]
          field_type = v[:_type]
          begin
            # 创建字段实例
            field_class = FieldRegistry.get_type(field_type)
            field = field_class.new
            field.from_db(v[:value] || v)
            data[k] = field.value
            puts "从数据库处理显式类型字段 #{k} (类型: #{field_type}) 成功"
          rescue => e
            puts "处理显式类型字段 #{k} (类型: #{field_type}) 错误: #{e.message}"
          end
          next
        end
        
        # 处理GeoJSON格式的坐标字段
        if v.is_a?(Hash) && v[:type] == 'Point' && v[:coordinates].is_a?(Array) && v[:coordinates].size == 2
          begin
            field = FieldRegistry.create_field('coordinate')
            field.from_db(v)
            data[k] = field.value
            puts "从数据库处理GeoJSON坐标字段 #{k} 成功"
            next
          rescue => e
            puts "处理GeoJSON坐标字段 #{k} 错误: #{e.message}"
          end
        end
        
        # 使用FieldRegistry检测字段类型
        field_type = FieldRegistry.detect_field_type(k, v)
        if field_type
          # 如果是自定义字段，使用FieldRegistry处理
          begin
            field_class = FieldRegistry.get_type(field_type)
            field = field_class.new
            if v.is_a?(Hash)
              field.from_db(v)
            else
              field.value = v
            end
            data[k] = field.value
            puts "从数据库处理字段 #{k} (类型: #{field_type}) 成功"
          rescue => e
            puts "处理字段 #{k} (类型: #{field_type}) 错误: #{e.message}"
          end
        elsif v.is_a?(Hash) || v.is_a?(Array)
          # 递归处理嵌套结构
          process_data_recursively(v)
        end
      end
    elsif data.is_a?(Array)
      # 处理数组
      data.each_with_index do |item, index|
        if item.is_a?(Hash) || item.is_a?(Array)
          process_data_recursively(item)
        end
      end
    end
  end
  

end
