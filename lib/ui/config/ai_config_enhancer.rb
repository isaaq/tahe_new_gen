# frozen_string_literal: true

# AI配置增强器
# 可选组件，用于通过AI智能补全组件配置
class AIConfigEnhancer
  # 检查AI是否启用
  def self.ai_enabled?
    # 检查是否配置了LLM服务
    return false unless defined?(LLMService)
    return false unless LLMService.instance
    
    # 检查API配置
    api_key = Common::C['llm_api_key'] rescue nil
    api_endpoint = Common::C['llm_api_endpoint'] rescue nil
    
    !api_key.nil? && !api_endpoint.nil?
  end
  
  # AI增强配置
  def self.enhance(component_type, config, context)
    return config unless ai_enabled?
    
    begin
      prompt = build_enhancement_prompt(component_type, config, context)
      ai_suggestions = call_llm_service(prompt)
      
      # 合并AI建议（AI建议优先级较低，不覆盖现有配置）
      merge_ai_suggestions(config, ai_suggestions)
    rescue => e
      puts "AI配置增强失败: #{e.message}" if ENV['RACK_ENV'] != 'production'
      config
    end
  end
  
  private
  
  # 构建AI提示词
  def self.build_enhancement_prompt(type, config, context)
    case type
    when 'tree'
      build_tree_prompt(config, context)
    when 'datatable'
      build_datatable_prompt(config, context)
    else
      build_generic_prompt(type, config, context)
    end
  end
  
  # 构建Tree组件的AI提示词
  def self.build_tree_prompt(config, context)
    url = config[:url] || ''
    scenario = context[:scenario] || 'unknown'
    
    <<~PROMPT
      你是一个UI组件配置专家。请根据以下信息为Layui树组件提供配置建议：

      当前配置：
      #{config.to_json}

      上下文信息：
      - 数据源URL: #{url}
      - 使用场景: #{scenario}
      - 是否联动: #{context[:linkage] ? '是' : '否'}

      请分析并建议以下配置项（只输出JSON，不要其他文字）：
      - initLevel: 合适的初始展开层级
      - accordion: 是否使用手风琴模式
      - width/height: 合适的尺寸
      - 其他优化建议

      建议格式：{"initLevel": 2, "accordion": true, "width": "300px"}
    PROMPT
  end
  
  # 构建DataTable组件的AI提示词
  def self.build_datatable_prompt(config, context)
    url = config[:url] || ''
    scenario = context[:scenario] || 'unknown'
    
    <<~PROMPT
      你是一个UI组件配置专家。请根据以下信息为Layui表格组件提供配置建议：

      当前配置：
      #{config.to_json}

      上下文信息：
      - 数据源URL: #{url}
      - 使用场景: #{scenario}
      - 是否联动: #{context[:linkage] ? '是' : '否'}

      请分析并建议以下配置项（只输出JSON，不要其他文字）：
      - limit: 合适的分页大小
      - cellMinWidth: 合适的列最小宽度
      - height: 合适的表格高度
      - 其他优化建议

      建议格式：{"limit": 15, "cellMinWidth": 80, "height": "full-200"}
    PROMPT
  end
  
  # 构建通用组件的AI提示词
  def self.build_generic_prompt(type, config, context)
    <<~PROMPT
      你是一个UI组件配置专家。请为#{type}组件提供配置建议：

      当前配置：
      #{config.to_json}

      上下文信息：
      #{context.to_json}

      请提供优化建议（只输出JSON格式的配置项）。
    PROMPT
  end
  
  # 调用LLM服务
  def self.call_llm_service(prompt)
    return {} unless defined?(LLMService)
    
    response = LLMService.instance.process(prompt)
    
    if response[:status] == 'success'
      # 尝试解析AI返回的JSON
      ai_result = response[:result]
      
      # 提取JSON部分（AI可能返回带解释的文字）
      json_match = ai_result.match(/\{.*\}/m)
      if json_match
        JSON.parse(json_match[0], symbolize_names: true)
      else
        {}
      end
    else
      {}
    end
  rescue => e
    puts "LLM服务调用失败: #{e.message}" if ENV['RACK_ENV'] != 'production'
    {}
  end
  
  # 合并AI建议到配置中
  def self.merge_ai_suggestions(config, ai_suggestions)
    return config unless ai_suggestions.is_a?(Hash)
    
    # AI建议只补充缺失的配置，不覆盖现有配置
    result = config.dup
    
    ai_suggestions.each do |key, value|
      unless result.key?(key) || result.key?(key.to_s)
        result[key] = value
      end
    end
    
    result
  end
end

# 便捷注册方法
def self.register_ai_enhancer(component_type)
  return unless AIConfigEnhancer.ai_enabled?
  
  ComponentConfigRegistry.register_processor(component_type, AIConfigEnhancer)
  puts "已注册AI增强器: #{component_type}" if ENV['RACK_ENV'] != 'production'
end

# 为AIConfigEnhancer添加便捷注册方法
class << AIConfigEnhancer
  def register_ai_enhancer(component_type)
    return unless ai_enabled?
    
    ComponentConfigRegistry.register_processor(component_type, self)
    puts "已注册AI增强器: #{component_type}" if ENV['RACK_ENV'] != 'production'
  end
end
