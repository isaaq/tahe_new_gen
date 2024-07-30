require_relative 'db_mongo'

module MongoCommonUtil
  # attr_accessor :db
  def common_data
    {
      _create_time: Time.now,
      _update_time: Time.now,
      _enabled: true,
    }
  end

  def load_model(file = nil)
    @db = DBMongo.new
    if file.nil?
    else
      txt = File.read(file)
      lines = txt.split("\n")
      lines.each do |l|
        parse(l)
      end
    end
    self
  end

  def [](key)
    # TODO 从.m文件中读取 目前读test目录需要修改

    # TODO 读取系统模型
    load_sys_models
    # TODO 缓存
    path = "./test/data/dsl/model/#{key.to_s}.m"

    if File.exist?(path)
      @model = load_model(path) if @model.nil?
      @model
    else
      # @mc[key.to_sym]
      found = Global.instance._sys_models&.find {|f| f._name == key}
      @db = DBMongo.new if @db.nil?
      unless found.nil?
        found.public_methods(false).each do |m|
          next unless m.name[0] == '_'
          parse "#{m.name} #{found.send m.name}"
        end
        self
      else
        table(key)
        self
      end
    end
  end

  def change_db(db_name, opts = {})
    @db = DBMongo.new(opts)
    @db.db = @db.db.use(db_name)
    self
  end


  def query(query_hash = {}, opts = {})
    mongo_parse_query!(query_hash)
    qry = @db.db[@db.table].find(query_hash)
    qry.sort(opts[:sort]) unless opts[:sort].nil?
    @db.db.close
    qry
  end

  def del(query_hash = {})
    del_data = @db.db[@db.table].find(query_hash).to_a
    r = @db.db[@db.table].delete_one(query_hash)
    # 垃圾箱
    Common::C[:audit_level] ||= 2
    if Common::C[:audit_level] != 0
      add_to_recyc(del_data, 'del')
    end
    @db.db.close
    r
  end

  def del_many(query_hash = {})
    del_data = @db.db[@db.table].find(query_hash).to_a
    r = @db.db[@db.table].delete_many(query_hash)
    # 垃圾箱
    Common::C[:audit_level] ||= 2
    if Common::C[:audit_level] != 0
      add_to_recyc(del_data, 'del_many')
    end
    @db.db.close
    r
  end

  def add(data = {}, opts = {})
    data.merge!(common_data)
    Common::C[:audit_level] ||= 2
    if Common::C[:audit_level] >= 3
      add_to_recyc(data, 'add')
    end
    r = @db.db[@db.table].insert_one(data)
    @db.db.close
    r
  end

  def update(query_hash = {}, data = {}, opts = {})
    common_update_data = {
      _update_time: Time.now,
    }
    data.merge!(common_update_data)
    r = @db.db[@db.table].find_one_and_update(query_hash, data)
    Common::C[:audit_level] ||= 2
    if Common::C[:audit_level] >= 2
      data = @db.db[@db.table].find(query_hash).to_a
      add_to_recyc(data, 'update')
    end
    @db.db.close
    r
  end

  def update_many(query_hash = {}, data = {}, opts = {})
    common_update_data = {
      _update_time: Time.now,
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

  def method_missing(m, *args, &block)
    p "missing #{m}"
  end

  def gen_sample_ui_code

  end

  private

  def add_to_recyc(del_data, type)
    data = { table: @db.table, data: del_data, type: type }
    data.merge!(common_data)
    @db.db[:recyc].insert_one(data)
  end

  def extends(params)
    if self.class.is_a?(BaseModel)

    end
  end

  def table(params)
    @db.table = params
  end

  def process_type(clazz)
    bs = clazz.new
    bs.build
  end

  def parse(code)
    return nil if code.match(/^\/\/ .+?/)
    code.strip!
    parsed_code = code.split(' ')
    if parsed_code.length > 0
      sym = parsed_code[0].to_sym
      cmd = { '↑': 'extends', '表': 'table' }
      type_list = ObjectSpace.each_object(Class).select { |klass| klass < BaseType }
      func = cmd[sym]&.to_sym || sym.to_s.gsub('_','').to_sym
      if func.nil?
        type_map = type_list.inject({}) { |t, i| t[i._name] = i; t }
        if !type_map.nil? && !type_map[sym].nil?
          process_type(type_map[sym])
        end
      else
        send(func, parsed_code[1]) if private_methods.include?(func)
      end
    end
  end

  class MongoResult
    def self.get_ret(db, qry)
      result = qry.to_a
      db.db.close
      p db.db.closed?
      result
    end
  end

  private

  # @param [Hash] qry
  def mongo_parse_query!(qry)
    # 全局搜索
    if qry.has_key?(:_global_search_str)

    end
    # 角色权限

  end

  def load_sys_models
    path = './lib/model/sys'
    # MSysPage._table
    # p Dir.entries(path)
    # @_sys_models
  end
end
