# frozen_string_literal: true

require 'erb'

# 插件测试用例生成器
class PluginTestGenerator
  TEST_TEMPLATE = <<~'TEMPLATE'
# frozen_string_literal: true

require_relative '<%= @test_helper_path %>'
require_relative '<%= @plugin_require_path %>'

class Test<%= @class_name %> < Test::Unit::TestCase
  def setup
    @plugin = <%= @class_name %>.new
  end
  
  def test_<%= @test_name %>
    # 测试用例
    <%= @test_logic %>
  end
  
  <% if @has_strategy_info %>
  def test_strategy_registration
    # 验证策略已注册
    strategy = Strategy.resolve(
      domain: '<%= @domain %>',
      action: '<%= @action %>',
      context: '<%= @context %>'
    )
    assert_not_nil strategy
    assert_instance_of <%= @class_name %>, strategy
  end
  <% end %>
end
  TEMPLATE
  
  def generate_test(plugin_config)
    @test_helper_path = '../../test_helper'
    @plugin_require_path = calculate_plugin_path(plugin_config)
    @class_name = plugin_config[:class_name]
    @test_name = 'basic_functionality'
    @test_logic = generate_test_logic(plugin_config)
    @has_strategy_info = !plugin_config[:domain].nil?
    @domain = plugin_config[:domain]
    @action = plugin_config[:action]
    @context = plugin_config[:context]
    
    ERB.new(TEST_TEMPLATE, trim_mode: '-').result(binding)
  end
  
  private
  
  def calculate_plugin_path(plugin_config)
    category_path = plugin_config[:category].gsub('_', '/')
    file_name = underscore(plugin_config[:class_name])
    "../../plugins/#{category_path}/#{file_name}"
  end
  
  def generate_test_logic(plugin_config)
    plugin_type = plugin_config[:type].to_s
    
    if plugin_type == 'strategy'
      action = plugin_config[:action].to_s
      if action == 'save'
        <<~RUBY
          result = @plugin.execute(
            data: { title: '测试', content: '内容' },
            collection: 'test_documents'
          )
          assert result[:success]
          assert_not_nil result[:document_id]
        RUBY
      elsif action == 'query'
        <<~RUBY
          result = @plugin.execute(
            query: {},
            collection: 'test_documents'
          )
          assert result[:success]
          assert_kind_of Array, result[:data]
        RUBY
      else
        <<~RUBY
          result = @plugin.execute({})
          assert result[:success]
        RUBY
      end
    elsif plugin_type == 'field_type'
      class_name = plugin_config[:class_name]
      <<~RUBY
        field = #{class_name}.new('test_field')
        valid, error = field.validate('test_value')
        assert valid, error
      RUBY
    else
      '# 自定义测试逻辑'
    end
  end
  
  def underscore(str)
    str.gsub(/::/, '/')
       .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
       .gsub(/([a-z\d])([A-Z])/, '\1_\2')
       .tr('-', '_')
       .downcase
  end
end

