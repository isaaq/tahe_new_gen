require_relative 'db_mongo'

module MongoCommonUtil
  attr_accessor :load_path

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
    self
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
    end

    # path = "./test/data/dsl/model/#{key}.m"
    # Global.instance._user_models.find {|f| f}
    models = ((Global.instance._sys_models || []) + Global.instance._user_models).flatten(1)

    found = models.find { |f| f._name == key.to_s }
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
    qry.model = @db.model
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
    data.merge!(common_data)
    Common::C[:audit_level] ||= 2
    add_to_recyc(data, 'add') if Common::C[:audit_level] >= 3
    r = @db.db[@db.table].insert_one(data)
    @db.db.close
    r
  end

  def update(query_hash = {}, data = {}, _opts = {})
    common_update_data = {
      _update_time: Time.now
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

  def update_many(query_hash = {}, data = {}, _opts = {})
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

  def method_missing(m, *_args)
    __p "missing #{m}"
  end

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

  # @param [Hash] qry
  def mongo_parse_query!(qry)
    # 全局搜索
    nil unless qry.has_key?(:_global_search_str)

    # 角色权限
    # Common::C[:auto_role_query]

    # 模型的额外属性
    # __p @db.model._fk
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
end
