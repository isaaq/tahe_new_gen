module SysModelCommon
  def _table(tbl_name = nil)
    @table = tbl_name unless tbl_name.nil?
    @table
  end

  def _name(name = nil)
    @name = name unless name.nil?
    @name
  end

  def _type(*names)
    @type = names unless names.nil?
    @type
  end

  def _structure(hash = nil)
    unless hash.nil?
      @struct_list ||= []
      hash&.at(0)&.each do |k, v|
        clz = Object.const_get(k)
        inst = clz.new
        @struct_list << inst
      rescue Exception => e
        @_err ||= []
        @_err << { err: e, obj: [k, v] }
        Common::M[:log_errors].add({ type: 'model_error', msg: e.to_s, obj: [k, v] }) if Common::C[:log_err] == 1
      end
    end
    @struct_list
  end

  # 获取模型的所有字段信息
  def fields
    fields_info = []
    
    # 处理结构定义中的字段
    if @struct_list && !@struct_list.empty?
      @struct_list.each_with_index do |field_instance, index|
        field_info = extract_field_info(field_instance, index)
        fields_info << field_info if field_info
      end
    end
    
    # 处理外键字段
    if @fks && !@fks.empty?
      @fks.each do |fk|
        field_info = {
          name: fk.name,
          display_name: fk.name,
          type: 'Link',
          field_type: '外键关联',
          is_foreign_key: true,
          link_to: fk.table,
          description: "关联到 #{fk.table} 表"
        }
        fields_info << field_info
      end
    end
    
    fields_info
  end

  # 提取字段信息
  def extract_field_info(field_instance, index)
    return nil unless field_instance
    
    field_info = {
      index: index,
      name: field_instance.name,
      display_name: field_instance.display_name,
      type: field_instance.class.name,
      field_type: get_field_type_name(field_instance.class),
      description: field_instance.description,
      is_system: field_instance.is_system,
      is_required: field_instance.is_required,
      is_searchable: field_instance.is_searchable,
      is_sortable: field_instance.is_sortable,
      is_global_search: field_instance.is_global_search,
      is_unique: field_instance.is_unique,
      is_file: field_instance.respond_to?(:is_file) ? field_instance.is_file : false,
      default_value: field_instance.value,
      length_range: field_instance.length_range,
      regex: field_instance.regex,
      regex_error_msg: field_instance.regex_error_msg
    }
    
    # 处理枚举类型的特殊属性
    if field_instance.class.name == 'Enum'
      field_info[:values] = field_instance.respond_to?(:values) ? field_instance.values : []
      field_info[:default_value] = field_instance.respond_to?(:default_value) ? field_instance.default_value : nil
    end
    
    # 处理链接类型的特殊属性
    if field_instance.class.name == 'Link'
      field_info[:link_to] = field_instance.respond_to?(:link_to) ? field_instance.link_to : nil
    end
    
    field_info
  end

  # 获取字段类型的友好名称（从配置读取，避免硬编码）
  def get_field_type_name(field_class)
    type_name = field_class.name
    
    # 尝试从配置文件加载映射
    type_names = load_field_type_names
    type_names[type_name] || type_name
  end
  
  # 加载字段类型名称映射
  def load_field_type_names
    @field_type_names ||= begin
      require 'yaml'
      config_path = File.join(__dir__, '../../ui/config/naming_convention_config.yml')
      if File.exist?(config_path)
        config = YAML.load_file(config_path)
        config['field_type_names'] || default_field_type_names
      else
        default_field_type_names
      end
    rescue => e
      default_field_type_names
    end
  end
  
  # 默认字段类型名称映射（防御性编程）
  def default_field_type_names
    {
      'Text' => '文本',
      'Number' => '数字',
      'Boolean' => '布尔值',
      'Date' => '日期',
      'DateTime' => '日期时间',
      'Enum' => '枚举',
      'Link' => '关联',
      'NumberRange' => '数字范围',
      'DateRange' => '日期范围',
      'Coordinate' => '坐标'
    }
  end

  class Fk
    attr_accessor :name, :table

    def initialize(name, table = nil)
      @name = name
      @table = table
    end
  end

  def _fk(fk = nil, table = nil)
    @fks ||= []
    temp = Fk.new(fk, table)
    @fks << temp unless fk.nil?
    @fks.find { |f| f.name == fk }
  end

  def _fks
    @fks
  end

  alias 表 _table
  alias 名 _name
  alias 型 _type
  alias 构 _structure
  alias 外 _fk
end