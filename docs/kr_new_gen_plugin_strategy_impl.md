# KR New Gen 策略驱动与插件式业务逻辑控制系统实现方案

## 1. 系统概述

为了增强 KR New Gen 系统的扩展性和灵活性，我们设计了一套策略驱动和插件式业务逻辑控制系统。该系统允许根据不同的业务场景和上下文，动态选择和执行不同的业务逻辑策略，而无需修改核心代码。

## 2. 核心目标

- 实现一套策略注册与选择机制（StrategyRegistry）
- 支持多种业务行为（如保存、提交、查询）的多种策略实现（如草稿、正常、暂存发布）
- 插件结构支持按 domain + action + context 三维度区分（如 ['order', 'submit', 'draft']）
- 策略实现类支持动态加载和自动注册
- 插件注册信息支持通过 DSL 或配置文件定义

## 3. 系统架构

### 3.1 目录结构

```
lib/
├── strategy/
│   ├── base_strategy.rb            # 策略基类
│   └── strategy_registry.rb        # 策略分发注册中心
├── plugins/
│   └── strategy/
│       ├── save/                   # 保存策略
│       │   ├── draft_save_strategy.rb
│       │   └── normal_save_strategy.rb
│       └── submit/                 # 提交策略
│           ├── draft_strategy.rb
│           └── publish_strategy.rb
├── dsl/
│   └── config/
│       └── strategy.yaml           # 策略配置文件
└── ui/
    └── meta/
        └── field_type.rb           # 字段类型定义
```

### 3.2 核心组件

#### 3.2.1 策略注册表（StrategyRegistry）

负责管理所有策略的注册和查找。提供 `resolve(domain:, action:, context:)` 方法，根据三维度查找对应的策略实现。

#### 3.2.2 基础策略（BaseStrategy）

所有具体策略的抽象基类，定义了策略的通用接口和生命周期方法。

#### 3.2.3 策略配置（strategy.yaml）

通过 YAML 配置文件定义策略的注册信息，支持动态加载和替换。

#### 3.2.4 字段类型（FieldType）

定义业务字段的类型、验证规则和行为特性，与策略系统结合使用。

## 4. 详细设计

### 4.1 策略注册表（StrategyRegistry）

```ruby
# lib/strategy/strategy_registry.rb
module Strategy
  class StrategyRegistry
    include Singleton
    
    def initialize
      @strategies = {}
      load_strategies_from_config
    end
    
    # 根据三维度查找策略
    def resolve(domain:, action:, context: 'default')
      key = [domain.to_s, action.to_s, context.to_s]
      strategy_class = @strategies.dig(*key)
      
      if strategy_class.nil?
        # 尝试查找默认策略
        strategy_class = @strategies.dig(domain.to_s, action.to_s, 'default')
      end
      
      raise "未找到策略: #{key.join('/')}" if strategy_class.nil?
      
      # 返回策略实例
      strategy_class.new
    end
    
    # 注册策略
    def register(domain, action, context, strategy_class)
      @strategies[domain.to_s] ||= {}
      @strategies[domain.to_s][action.to_s] ||= {}
      @strategies[domain.to_s][action.to_s][context.to_s] = strategy_class
    end
    
    private
    
    # 从配置文件加载策略
    def load_strategies_from_config
      config_path = File.join(Dir.pwd, 'lib', 'dsl', 'config', 'strategy.yaml')
      return unless File.exist?(config_path)
      
      config = YAML.load_file(config_path)
      config['strategies'].each do |strategy|
        domain = strategy['domain']
        action = strategy['action']
        context = strategy['context'] || 'default'
        class_name = strategy['class']
        
        # 动态加载策略类
        strategy_class = Object.const_get(class_name)
        register(domain, action, context, strategy_class)
      end
    end
  end
  
  # 便捷方法
  def self.registry
    StrategyRegistry.instance
  end
  
  def self.resolve(domain:, action:, context: 'default')
    registry.resolve(domain: domain, action: action, context: context)
  end
 end
```

### 4.2 基础策略（BaseStrategy）

```ruby
# lib/strategy/base_strategy.rb
module Strategy
  class BaseStrategy
    # 策略执行前的钩子
    def before_execute(params = {})
      # 子类可重写
    end
    
    # 策略执行
    def execute(params = {})
      before_execute(params)
      result = perform(params)
      after_execute(params, result)
      result
    end
    
    # 策略执行后的钩子
    def after_execute(params = {}, result = nil)
      # 子类可重写
    end
    
    # 具体策略实现（子类必须重写）
    def perform(params = {})
      raise NotImplementedError, "#{self.class} 必须实现 perform 方法"
    end
    
    # 策略自注册方法
    def self.register(domain, action, context = 'default')
      Strategy.registry.register(domain, action, context, self)
    end
    
    # 当模块被包含时自动注册
    def self.included(base)
      base.extend(ClassMethods)
    end
    
    module ClassMethods
      def strategy_for(domain, action, context = 'default')
        Strategy.registry.register(domain, action, context, self)
      end
    end
  end
end
```

### 4.3 示例策略实现

```ruby
# lib/plugins/strategy/save/draft_save_strategy.rb
require_relative '../../../strategy/base_strategy'

module Plugins
  module Strategy
    module Save
      class DraftSaveStrategy < ::Strategy::BaseStrategy
        # 自动注册策略
        strategy_for 'document', 'save', 'draft'
        
        def before_execute(params = {})
          # 验证必要参数
          raise "缺少必要参数: data" unless params[:data]
          
          # 添加草稿标记
          params[:data][:_draft] = true
          params[:data][:_draft_time] = Time.now
        end
        
        def perform(params = {})
          data = params[:data]
          collection = params[:collection] || 'drafts'
          
          # 使用 MongoDB 存储草稿数据
          result = Mongo::Client.new(["localhost:27017"], database: 'kr_new_gen')[collection].insert_one(data)
          
          # 返回结果
          {
            success: true,
            draft_id: result.inserted_id.to_s,
            message: "草稿已保存"
          }
        end
        
        def after_execute(params = {}, result = nil)
          # 记录日志
          puts "草稿已保存: #{result[:draft_id]}" if result && result[:success]
        end
      end
    end
  end
end
```

### 4.4 字段类型定义（FieldType）

```ruby
# lib/ui/meta/field_type.rb
module UI
  module Meta
    class FieldType
      attr_reader :name, :type, :options
      
      VALID_TYPES = [
        :string, :text, :integer, :float, :boolean, :date, :datetime,
        :enum, :array, :object, :reference, :file, :image, :number_range
      ]
      
      def initialize(name, type, options = {})
        @name = name.to_s
        @type = validate_type(type)
        @options = default_options.merge(options)
      end
      
      def required?
        !!@options[:required]
      end
      
      def searchable?
        !!@options[:searchable]
      end
      
      def validate(value)
        # 必填验证
        if required? && (value.nil? || value.to_s.empty?)
          return [false, "#{@name} 不能为空"]
        end
        
        # 正则验证
        if @options[:pattern] && !value.to_s.match?(@options[:pattern])
          return [false, "#{@name} 格式不正确"]
        end
        
        # 类型特定验证
        case @type
        when :integer, :float
          # 数值范围验证
          if @options[:min] && value.to_f < @options[:min]
            return [false, "#{@name} 不能小于 #{@options[:min]}"]
          end
          
          if @options[:max] && value.to_f > @options[:max]
            return [false, "#{@name} 不能大于 #{@options[:max]}"]
          end
        when :string, :text
          # 字符串长度验证
          if @options[:min_length] && value.to_s.length < @options[:min_length]
            return [false, "#{@name} 长度不能小于 #{@options[:min_length]}"]
          end
          
          if @options[:max_length] && value.to_s.length > @options[:max_length]
            return [false, "#{@name} 长度不能超过 #{@options[:max_length]}"]
          end
        when :enum
          # 枚举值验证
          if @options[:values] && !@options[:values].include?(value)
            return [false, "#{@name} 必须是以下值之一: #{@options[:values].join(', ')}"]
          end
        when :number_range
          # 数值范围验证
          if value.is_a?(Hash) && (value[:min] || value[:max])
            if value[:min] && value[:max] && value[:min] > value[:max]
              return [false, "#{@name} 的最小值不能大于最大值"]
            end
          else
            return [false, "#{@name} 必须包含 min 或 max 值"]
          end
        end
        
        [true, nil]
      end
      
      def to_mongo(value)
        # 将字段值转换为适合 MongoDB 存储的格式
        case @type
        when :date
          value.is_a?(Date) ? value : Date.parse(value.to_s)
        when :datetime
          value.is_a?(Time) ? value : Time.parse(value.to_s)
        when :integer
          value.to_i
        when :float
          value.to_f
        when :boolean
          !!value
        else
          value
        end
      rescue => e
        # 转换失败时返回原值
        value
      end
      
      private
      
      def validate_type(type)
        type = type.to_sym
        raise "无效的字段类型: #{type}" unless VALID_TYPES.include?(type)
        type
      end
      
      def default_options
        {
          required: false,
          searchable: false,
          system: false,
          description: ""
        }
      end
    end
  end
end
```

### 4.5 策略配置文件

```yaml
# lib/dsl/config/strategy.yaml
strategies:
  # 保存策略
  - domain: document
    action: save
    context: draft
    class: Plugins::Strategy::Save::DraftSaveStrategy
  
  - domain: document
    action: save
    context: normal
    class: Plugins::Strategy::Save::NormalSaveStrategy
  
  # 提交策略
  - domain: document
    action: submit
    context: draft
    class: Plugins::Strategy::Submit::DraftStrategy
  
  - domain: document
    action: submit
    context: publish
    class: Plugins::Strategy::Submit::PublishStrategy
```

## 5. 使用示例

### 5.1 在控制器中使用策略

```ruby
# api/controllers/document_controller.rb
post '/api/document/save' do
  data = JSON.parse(request.body.read)
  context = params[:context] || 'normal'
  
  # 根据上下文选择并执行保存策略
  strategy = Strategy.resolve(domain: 'document', action: 'save', context: context)
  result = strategy.execute(data: data)
  
  content_type :json
  result.to_json
end
```

### 5.2 字段类型的使用

```ruby
# 定义文档字段
document_fields = [
  UI::Meta::FieldType.new('title', :string, required: true, min_length: 3, max_length: 100),
  UI::Meta::FieldType.new('content', :text, searchable: true),
  UI::Meta::FieldType.new('status', :enum, values: ['draft', 'published', 'archived'], default: 'draft'),
  UI::Meta::FieldType.new('price_range', :number_range, searchable: true),
  UI::Meta::FieldType.new('created_at', :datetime, system: true)
]

# 验证文档数据
def validate_document(data)
  errors = []
  
  document_fields.each do |field|
    if data.key?(field.name)
      valid, message = field.validate(data[field.name])
      errors << message unless valid
    end
  end
  
  errors
end
```

## 6. 与现有系统集成

策略系统设计为与现有的 KR New Gen 系统无缝集成：

1. **与现有模型集成**：策略可以操作现有的 MongoDB 模型
2. **与 UI 系统集成**：字段类型定义可以与现有的 UI 组件系统结合
3. **与 API 层集成**：策略可以在 Sinatra 控制器中使用

## 7. 扩展性考虑

1. **新增策略**：只需创建新的策略类并注册
2. **新增字段类型**：扩展 FieldType 类支持新的数据类型
3. **配置热更新**：支持不重启应用的情况下更新策略配置

## 8. 后续优化方向

1. **策略缓存机制**：提高策略解析性能
2. **策略组合**：支持多个策略的组合使用
3. **策略版本控制**：支持策略的版本管理和回滚
4. **可视化配置**：提供 Web 界面配置策略
