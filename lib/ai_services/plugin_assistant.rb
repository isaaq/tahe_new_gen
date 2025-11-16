# frozen_string_literal: true

require 'singleton'
require 'json'
require_relative '../../lib/plugins/store/plugin_store'

# 插件助手 - AI辅助插件推荐和配置
class PluginAssistant
  include Singleton
  
  def initialize
    @store = PluginStore.instance
    @llm_service = defined?(LLMService) ? LLMService.instance : nil
    @prompt_service = defined?(PromptTemplateService) ? PromptTemplateService.instance : nil
  end
  
  # 根据需求推荐插件
  def recommend_plugins(requirement)
    return { error: 'AI service not available' } unless ai_available?
    
    # 获取所有可用插件
    all_plugins = @store.list_plugins
    
    # 构建提示词
    prompt = build_recommendation_prompt(requirement, all_plugins)
    
    # 调用AI服务
    response = @llm_service.process(prompt)
    
    if response && response[:status] == 'success'
      # 解析AI返回的推荐
      recommendations = parse_recommendations(response[:result], all_plugins)
      
      {
        status: 'success',
        recommendations: recommendations[:must_have] || [],
        optional: recommendations[:optional] || [],
        explanation: recommendations[:explanation] || ''
      }
    else
      {
        status: 'error',
        error: 'AI recommendation failed'
      }
    end
  rescue => e
    {
      status: 'error',
      error: e.message
    }
  end
  
  # 帮助配置插件
  def configure_plugin(plugin_id, user_input)
    plugin = @store.get_plugin(plugin_id)
    return { error: 'Plugin not found' } unless plugin
    
    return { error: 'AI service not available' } unless ai_available?
    
    config_schema = plugin[:config_schema] || {}
    
    # 构建配置提示词
    prompt = build_configuration_prompt(plugin, user_input, config_schema)
    
    # 调用AI服务
    response = @llm_service.process(prompt)
    
    if response && response[:status] == 'success'
      # 解析AI返回的配置
      config = parse_configuration(response[:result], config_schema)
      
      # 验证配置
      validation = validate_config(config, config_schema)
      
      if validation[:valid]
        {
          status: 'success',
          config: config,
          explanation: validation[:explanation] || ''
        }
      else
        {
          status: 'error',
          error: validation[:error] || 'Configuration validation failed'
        }
      end
    else
      {
        status: 'error',
        error: 'AI configuration failed'
      }
    end
  rescue => e
    {
      status: 'error',
      error: e.message
    }
  end
  
  # 推荐插件组合
  def suggest_plugin_combination(requirements)
    return { error: 'AI service not available' } unless ai_available?
    
    # 获取所有可用插件
    all_plugins = @store.list_plugins
    
    # 构建组合推荐提示词
    prompt = build_combination_prompt(requirements, all_plugins)
    
    # 调用AI服务
    response = @llm_service.process(prompt)
    
    if response && response[:status] == 'success'
      # 解析AI返回的组合推荐
      combination = parse_combination(response[:result], all_plugins)
      
      {
        status: 'success',
        plugins: combination[:plugins] || [],
        installation_order: combination[:order] || [],
        config_guide: combination[:config] || {}
      }
    else
      {
        status: 'error',
        error: 'AI combination recommendation failed'
      }
    end
  rescue => e
    {
      status: 'error',
      error: e.message
    }
  end
  
  private
  
  def ai_available?
    @llm_service && @prompt_service
  end
  
  def build_recommendation_prompt(requirement, plugins)
    plugin_list = plugins.map do |p|
      "- #{p[:name]} (#{p[:plugin_id]}): #{p[:description]} [标签: #{p[:tags].join(', ')}]"
    end.join("\n")
    
    if @prompt_service && @prompt_service.respond_to?(:get_template)
      begin
        @prompt_service.get_template('recommend_plugins', {
          requirement: requirement,
          plugins: plugin_list
        })
      rescue
        default_recommendation_prompt(requirement, plugin_list)
      end
    else
      default_recommendation_prompt(requirement, plugin_list)
    end
  end
  
  def default_recommendation_prompt(requirement, plugin_list)
    <<~PROMPT
      你是一个插件推荐专家。根据用户需求，从以下插件列表中选择最合适的插件。
      
      用户需求：
      #{requirement}
      
      可用插件列表：
      #{plugin_list}
      
      请分析需求并推荐：
      1. 必须安装的插件（must_have）
      2. 可选插件（optional）
      3. 推荐理由（explanation）
      
      请以JSON格式返回：
      {
        "must_have": ["plugin_id1", "plugin_id2"],
        "optional": ["plugin_id3", "plugin_id4"],
        "explanation": "推荐理由..."
      }
    PROMPT
  end
  
  def build_configuration_prompt(plugin, user_input, config_schema)
    schema_desc = config_schema['fields'] ? config_schema['fields'].map do |field|
      "- #{field['name']}: #{field['type']} - #{field['description']} (默认值: #{field['default']})"
    end.join("\n") : '无配置项'
    
    if @prompt_service && @prompt_service.respond_to?(:get_template)
      begin
        @prompt_service.get_template('configure_plugin', {
          plugin_name: plugin[:name] || '',
          plugin_description: plugin[:description] || '',
          user_input: user_input,
          config_schema: schema_desc
        })
      rescue
        default_configuration_prompt(plugin, user_input, schema_desc)
      end
    else
      default_configuration_prompt(plugin, user_input, schema_desc)
    end
  end
  
  def default_configuration_prompt(plugin, user_input, schema_desc)
    <<~PROMPT
      你是一个插件配置专家。根据用户输入，为插件生成合适的配置。
      
      插件名称：#{plugin[:name]}
      插件描述：#{plugin[:description]}
      
      用户输入：
      #{user_input}
      
      配置项说明：
      #{schema_desc}
      
      请根据用户输入生成配置，以JSON格式返回：
      {
        "config": {
          "field1": "value1",
          "field2": "value2"
        },
        "explanation": "配置说明..."
      }
    PROMPT
  end
  
  def build_combination_prompt(requirements, plugins)
    plugin_list = plugins.map do |p|
      "- #{p[:name]} (#{p[:plugin_id]}): #{p[:description]} [类别: #{p[:category]}]"
    end.join("\n")
    
    if @prompt_service && @prompt_service.respond_to?(:get_template)
      begin
        @prompt_service.get_template('suggest_plugin_combination', {
          requirements: requirements,
          plugins: plugin_list
        })
      rescue
        default_combination_prompt(requirements, plugin_list)
      end
    else
      default_combination_prompt(requirements, plugin_list)
    end
  end
  
  def default_combination_prompt(requirements, plugin_list)
    <<~PROMPT
      你是一个插件组合专家。根据用户需求，推荐一组可以协同工作的插件。
      
      用户需求：
      #{requirements}
      
      可用插件列表：
      #{plugin_list}
      
      请推荐插件组合，包括：
      1. 插件列表
      2. 安装顺序
      3. 配置指南
      
      请以JSON格式返回：
      {
        "plugins": ["plugin_id1", "plugin_id2"],
        "order": ["plugin_id1", "plugin_id2"],
        "config": {
          "plugin_id1": {"field1": "value1"},
          "plugin_id2": {"field2": "value2"}
        }
      }
    PROMPT
  end
  
  def parse_recommendations(ai_result, all_plugins)
    # 尝试提取JSON
    json_match = ai_result.match(/\{.*\}/m)
    return { must_have: [], optional: [], explanation: '' } unless json_match
    
    begin
      result = JSON.parse(json_match[0], symbolize_names: true)
      
      # 验证插件ID是否存在
      must_have = (result[:must_have] || []).select { |id| all_plugins.any? { |p| p[:plugin_id] == id } }
      optional = (result[:optional] || []).select { |id| all_plugins.any? { |p| p[:plugin_id] == id } }
      
      {
        must_have: must_have,
        optional: optional,
        explanation: result[:explanation] || ''
      }
    rescue
      { must_have: [], optional: [], explanation: '' }
    end
  end
  
  def parse_configuration(ai_result, config_schema)
    json_match = ai_result.match(/\{.*\}/m)
    return {} unless json_match
    
    begin
      result = JSON.parse(json_match[0], symbolize_names: true)
      result[:config] || {}
    rescue
      {}
    end
  end
  
  def parse_combination(ai_result, all_plugins)
    json_match = ai_result.match(/\{.*\}/m)
    return { plugins: [], order: [], config: {} } unless json_match
    
    begin
      result = JSON.parse(json_match[0], symbolize_names: true)
      
      plugins = (result[:plugins] || []).select { |id| all_plugins.any? { |p| p[:plugin_id] == id } }
      order = (result[:order] || plugins).select { |id| all_plugins.any? { |p| p[:plugin_id] == id } }
      
      {
        plugins: plugins,
        order: order,
        config: result[:config] || {}
      }
    rescue
      { plugins: [], order: [], config: {} }
    end
  end
  
  def validate_config(config, config_schema)
    return { valid: true } unless config_schema['fields']
    
    errors = []
    config_schema['fields'].each do |field|
      field_name = field['name']
      field_type = field['type']
      required = field['required'] || false
      
      if required && !config.key?(field_name.to_sym) && !config.key?(field_name)
        errors << "#{field_name} 是必填项"
      end
      
      if config.key?(field_name.to_sym) || config.key?(field_name)
        value = config[field_name.to_sym] || config[field_name]
        # 简单的类型验证
        case field_type
        when 'integer'
          errors << "#{field_name} 必须是整数" unless value.is_a?(Integer)
        when 'boolean'
          errors << "#{field_name} 必须是布尔值" unless [true, false].include?(value)
        end
      end
    end
    
    if errors.empty?
      { valid: true }
    else
      { valid: false, error: errors.join(', ') }
    end
  end
end

