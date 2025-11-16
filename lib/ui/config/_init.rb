# frozen_string_literal: true

# UI配置系统初始化文件
# 注册所有配置映射器和AI处理器

require_relative 'component_config_registry'
require_relative 'mappers/tree_config_mapper'
require_relative 'mappers/datatable_config_mapper'
require_relative 'relation_registry'
require_relative 'model_metadata_helper'

# 注册配置映射器
ComponentConfigRegistry.register_mapper('tree', TreeConfigMapper)
ComponentConfigRegistry.register_mapper('datatable', DatatableConfigMapper)

puts "UI配置系统已初始化，已注册配置映射器" if ENV['RACK_ENV'] != 'production'

# 启动时扫描模型定义（可选）
begin
  RelationRegistry.auto_discover_models!
rescue => e
  puts "⚠️  模型扫描失败: #{e.message}" if ENV['RACK_ENV'] != 'production'
end

