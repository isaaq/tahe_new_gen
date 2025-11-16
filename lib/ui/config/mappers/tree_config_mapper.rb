# frozen_string_literal: true

# Tree组件配置映射器
# 负责将 kr:tree 的粗粒度配置转换为 l:tree 的细粒度配置
class TreeConfigMapper
  # 默认配置（约定俗成）
  DEFAULTS = {
    skin: 'laySimple',
    iconStyle: 'dtreefont',
    initLevel: 1,
    dataFormat: 'list',
    dataStyle: 'layuiStyle',
    method: 'post',
    width: '100%',
    height: '100%',
    response: {
      statusName: 'code',
      statusCode: 0,
      message: 'msg',
      rootName: 'data'
    }
  }.freeze
  
  # 条件配置（规则引擎）
  CONDITIONAL_RULES = {
    search_true: {
      toolbar: true,
      toolbarWay: 'follow',
      toolbarShow: "['searchIcon']"
    },
    toolbar_buttons: {
      'add' => { menubarId: 'btn-add', icon: 'layui-icon-add-1', title: '添加' },
      'refresh' => { menubarId: 'btn-refresh', icon: 'layui-icon-refresh', title: '刷新' },
      'expand' => { menubarId: 'btn-expand', icon: 'layui-icon-down', title: '展开' },
      'collapse' => { menubarId: 'btn-collapse', icon: 'layui-icon-right', title: '收起' }
    }
  }.freeze
  
  # 上下文推断规则
  CONTEXT_RULES = {
    org_tree: {
      accordion: true,
      initLevel: 2,
      showLine: true
    },
    category_tree: {
      accordion: false,
      initLevel: 3,
      showLine: true
    },
    file_tree: {
      accordion: false,
      initLevel: 1,
      showLine: true,
      onlyIconControl: true
    }
  }.freeze
  
  # 基础映射：将kr属性转换为默认l配置
  def self.map_defaults(kr_attrs)
    config = DEFAULTS.dup
    
    # 直接映射的属性
    direct_mappings = %w[url method width height]
    direct_mappings.each do |attr|
      config[attr.to_sym] = kr_attrs[attr] if kr_attrs[attr]
    end
    
    config
  end
  
  # 条件映射：根据kr属性应用规则
  def self.map_conditional(kr_attrs, base_config)
    config = base_config.dup
    
    # search属性处理
    if kr_attrs['search'] == 'true'
      config.merge!(CONDITIONAL_RULES[:search_true])
    end
    
    # toolbar属性处理
    if kr_attrs['toolbar']
      buttons = kr_attrs['toolbar'].split(',')
      toolbar_ext = buttons.map { |btn| CONDITIONAL_RULES[:toolbar_buttons][btn.strip] }.compact
      config[:toolbarExt] = toolbar_ext if toolbar_ext.any?
    end
    
    # checkbar属性处理
    if kr_attrs['checkbar'] == 'true'
      config[:checkbar] = true
      config[:checkbarType] = kr_attrs['check_type'] || 'all'
    end
    
    # contextmenu属性处理
    if kr_attrs['contextmenu'] == 'true'
      config[:contextmenu] = true
      config[:menubar] = true
    end
    
    config
  end
  
  # 上下文推断：从URL和场景推断配置
  def self.infer_from_context(config, context)
    result = config.dup
    
    # 从URL推断数据类型
    url = result[:url].to_s
    if url.include?('org')
      result.merge!(CONTEXT_RULES[:org_tree])
    elsif url.include?('category')
      result.merge!(CONTEXT_RULES[:category_tree])
    elsif url.include?('file')
      result.merge!(CONTEXT_RULES[:file_tree])
    end
    
    # 从场景推断配置
    scenario = context[:scenario]
    case scenario
    when 'tree_table_layout'
      # 在树表联动场景中，树通常在左侧，需要合适的尺寸
      result[:width] ||= '300px'
      result[:height] ||= '500px'
    when 'sidebar_tree'
      # 在侧边栏场景中
      result[:width] ||= '100%'
      result[:height] ||= '100%'
      result[:accordion] = true
    end
    
    result
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
    if config[:initLevel] && config[:initLevel] < 0
      errors << "initLevel 必须大于等于0"
    end
    
    if config[:width] && !config[:width].match?(/\d+(px|%|em|rem)/)
      errors << "width 格式无效，应为数字+单位格式"
    end
    
    errors
  end
  
  # 序列化配置为字符串（用于生成l:tree属性）
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

