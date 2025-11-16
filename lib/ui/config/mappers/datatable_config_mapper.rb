# frozen_string_literal: true

# DataTable组件配置映射器
# 负责将 kr:datatable 的粗粒度配置转换为 l:table 的细粒度配置
class DatatableConfigMapper
  # 默认配置（约定俗成）
  DEFAULTS = {
    method: 'post',
    cellMinWidth: 60,
    skin: 'line',
    size: '',
    even: false,
    width: '100%',
    page: true,
    limit: 10,
    limits: [10, 20, 50, 100],
    response: {
      statusName: 'code',
      statusCode: 0,
      msgName: 'msg',
      dataName: 'data',
      countName: 'count'
    }
  }.freeze
  
  # 条件配置（规则引擎）
  CONDITIONAL_RULES = {
    page_true: {
      page: true,
      limit: 10,
      limits: [10, 20, 50, 100]
    },
    toolbar_default: {
      toolbar: '#toolbarDemo',
      defaultToolbar: ['filter', 'exports', 'print']
    },
    frozen_cols: {
      fixed: 'left'
    },
    action_col: {
      fixed: 'right',
      toolbar: '#barDemo'
    }
  }.freeze
  
  # 上下文推断规则
  CONTEXT_RULES = {
    user_table: {
      limit: 10,
      cellMinWidth: 80,
      height: 'full-220'
    },
    org_table: {
      limit: 20,
      cellMinWidth: 100,
      height: 'full-200'
    },
    log_table: {
      limit: 50,
      cellMinWidth: 60,
      height: 'full-300'
    }
  }.freeze
  
  # 基础映射：将kr属性转换为默认l配置
  def self.map_defaults(kr_attrs)
    config = DEFAULTS.dup
    
    # 直接映射的属性
    direct_mappings = %w[url method width height cellMinWidth skin size]
    direct_mappings.each do |attr|
      config[attr.to_sym] = kr_attrs[attr] if kr_attrs[attr]
    end
    
    config
  end
  
  # 条件映射：根据kr属性应用规则
  def self.map_conditional(kr_attrs, base_config)
    config = base_config.dup
    
    # page属性处理
    if kr_attrs['page'] == 'true'
      config.merge!(CONDITIONAL_RULES[:page_true])
      
      # 自定义分页配置
      config[:limit] = kr_attrs['limit'].to_i if kr_attrs['limit']
      if kr_attrs['limits']
        limits_str = kr_attrs['limits']
        config[:limits] = JSON.parse(limits_str) rescue [10, 20, 50, 100]
      end
    elsif kr_attrs['page'] == 'false'
      config[:page] = false
      config.delete(:limit)
      config.delete(:limits)
    end
    
    # toolbar属性处理
    if kr_attrs['toolbar'] == 'true'
      config.merge!(CONDITIONAL_RULES[:toolbar_default])
    elsif kr_attrs['toolbar']
      config[:toolbar] = "##{kr_attrs['toolbar']}"
    end
    
    # frozen-cols属性处理
    if kr_attrs['frozen-cols']
      frozen_count = kr_attrs['frozen-cols'].to_i
      config[:frozenCols] = frozen_count
    end
    
    # action-col属性处理
    if kr_attrs['action-col'] == 'true'
      config[:actionCol] = true
      config[:actionColToolbar] = '#actionToolbar'
    end
    
    # even属性处理
    config[:even] = true if kr_attrs['even'] == 'true'
    
    # sort属性处理
    if kr_attrs['sort'] == 'true'
      config[:initSort] = { field: 'id', type: 'asc' }
    end
    
    # checkbox属性处理
    if kr_attrs['checkbox'] == 'true'
      config[:checkbox] = true
    end
    
    config
  end
  
  # 上下文推断：从URL和场景推断配置
  def self.infer_from_context(config, context)
    result = config.dup
    
    # 从URL推断数据类型
    url = result[:url].to_s
    if url.include?('user')
      result.merge!(CONTEXT_RULES[:user_table])
    elsif url.include?('org')
      result.merge!(CONTEXT_RULES[:org_table])
    elsif url.include?('log')
      result.merge!(CONTEXT_RULES[:log_table])
    end
    
    # 从场景推断配置
    scenario = context[:scenario]
    case scenario
    when 'tree_table_layout'
      # 在树表联动场景中，表格通常在右侧
      result[:width] ||= '100%'
      result[:height] ||= 'full-200'
      # 默认启用分页
      result[:page] = true unless result.key?(:page)
    when 'search_table'
      # 在搜索表格场景中
      result[:page] = true
      result[:limit] ||= 15
    when 'crud_table'
      # 在CRUD表格场景中
      result[:page] = true
      result[:toolbar] ||= '#toolbarDemo'
      result[:defaultToolbar] ||= ['filter', 'exports', 'print']
    end
    
    # 从父组件推断配置
    parent = context[:parent_component]
    if parent&.is_a?(TreeTableLayoutItem)
      # 在树表联动中，表格应该响应树的选择
      result[:where] ||= {}
    end
    
    result
  end
  
  # 生成列配置
  def self.build_columns_config(kr_attrs, context = {})
    columns = []
    
    # 处理冻结列
    if kr_attrs['frozen-cols']
      frozen_count = kr_attrs['frozen-cols'].to_i
      (0...frozen_count).each do |i|
        columns << {
          type: 'checkbox',
          fixed: 'left',
          width: 50
        } if i == 0
      end
    end
    
    # 处理常规列
    if kr_attrs['columns']
      columns_config = JSON.parse(kr_attrs['columns']) rescue []
      columns += columns_config
    end
    
    # 处理操作列
    if kr_attrs['action-col'] == 'true'
      columns << {
        title: '操作',
        fixed: 'right',
        toolbar: '#actionToolbar',
        width: 150
      }
    end
    
    columns
  end
  
  # 验证配置的完整性
  def self.validate(config)
    errors = []
    
    # 必需属性检查
    required_attrs = %w[url]
    required_attrs.each do |attr|
      errors << "缺少必需属性: #{attr}" unless config[attr.to_sym] || config[attr]
    end
    
    # 属性值验证
    if config[:limit] && config[:limit] < 1
      errors << "limit 必须大于0"
    end
    
    if config[:cellMinWidth] && config[:cellMinWidth] < 30
      errors << "cellMinWidth 建议大于30"
    end
    
    errors
  end
  
  # 序列化配置为字符串（用于生成l:table属性）
  def self.serialize(config)
    config.map do |key, value|
      case value
      when Hash
        "#{key}='#{value.to_json}'"
      when Array
        "#{key}='#{value.to_json}'"
      when String
        "#{key}='#{value}'"
      when true
        "#{key}='true'"
      when false
        "#{key}='false'"
      else
        "#{key}=#{value}"
      end
    end.join(' ')
  end
end

