# kr_new_gen - 插件化与策略驱动增强能力说明

本文档详细描述了 `kr_new_gen` 项目中的"插件化"与"策略驱动"能力模块，这些模块在原有通用功能基础上新增，提供了更灵活、可扩展的业务逻辑处理方式。

---

## 🧠 增强能力概述

| 能力模块             | 描述                                                                 |
|----------------------|----------------------------------------------------------------------|
| 策略执行层 Strategy  | 将业务动作（如保存、查询等）解耦为不同策略实现，统一接口、配置决定行为 |
| 模式化数据策略       | 支持如"草稿模式"、"暂存/发布"、"缓存查询"、"联动保存"等业务语义      |
| 插件式组件模型       | UI、字段、验证、行为可由插件注册，允许不同项目自由组合                    |
| 业务字段语义扩展     | 字段支持复合结构（如日期范围）、正则匹配、权限控制、自动填充等            |
| 元数据驱动            | 支持通过元配置生成 CRUD + 查询等逻辑流程                               |
| AI 补全与辅助        | 接入 AI 模型辅助生成 DSL、表单字段、业务逻辑（如 prompt patch）          |

## 🔄 核心流程

1. **策略注册**：系统启动时加载所有策略实现并注册到 `StrategyRegistry`
2. **策略解析**：根据 `domain`、`action` 和 `context` 解析出具体的策略实现
3. **策略执行**：执行策略的 `before_execute`、`perform` 和 `after_execute` 方法
4. **结果返回**：返回策略执行结果，包含成功状态和数据

## 🏗️ 架构流程

```plaintext
  DSL 配置 (strategy.yaml)
      ↓
  策略注册中心 (StrategyRegistry)
      ↓
  控制器/服务层 (根据 domain/action/context 选择策略)
      ↓
  具体策略实现 (DraftSaveStrategy/NormalSaveStrategy等)
      ↓
  数据访问层 (MongoDB/缓存/外部服务)
      ↓
  返回处理结果
```

## 📌 关键特性

- **灵活的策略注册**：支持通过代码或 YAML 配置注册策略
- **多维策略选择**：基于 `domain`、`action` 和 `context` 三个维度选择策略
- **生命周期钩子**：提供 `before_execute` 和 `after_execute` 钩子
- **字段类型系统**：内置丰富字段类型和验证规则
- **无缝集成**：与现有 KR New Gen 系统无缝集成

# kr_new_gen 插件体系类别与能力清单

本清单详细说明了 `kr_new_gen` 插件机制中支持的插件类别及其对应的功能能力。

## 🔌 插件类别一览

| 插件类别       | 描述                                                  | 实现状态 | 示例 |
|----------------|-------------------------------------------------------|----------|------|
| 策略插件       | 定义业务动作（如 save/query/submit）的执行策略        | ✅ 已实现 | 草稿保存策略、发布策略 |
| 字段类型插件   | 定义业务字段的类型、验证规则、默认值、复合结构等       | ✅ 已实现 | 数值范围、日期范围、关联选择器 |
| 表单行为插件   | 控制表单的交互行为、数据预处理、联动逻辑等             | 🚧 开发中 | 自动填充、字段联动 |
| 数据源插件     | 支持自定义数据源的连接、字段映射、缓存策略等           | 🚧 开发中 | 远程 API 表格、混合缓存查询 |
| 权限插件       | 注册字段或模型层级的数据权限校验策略                   | 📅 规划中 | 门店隔离、数据权限 |
| 操作钩子插件   | 注入 before/after/save/query/delete 等操作钩子         | ✅ 部分实现 | 保存前校验、删除后清理 |
| UI 组件插件    | 注册新的可视化组件，支持配置项、渲染逻辑、交互行为等   | 📅 规划中 | 自定义表格、图表 |
| DSL 语义插件   | 扩展 DSL 层的语义、指令或结构                          | 📅 规划中 | 自定义指令、循环逻辑 |
| 渲染插件       | 控制不同前端框架的渲染目标生成                         | 📅 规划中 | Vue/React 组件生成 |
| AI Prompt 插件 | 接入 AI 生成提示、生成字段定义、校验规则、字段翻译等   | 📅 规划中 | 自动生成表单、字段翻译 |

## 🧩 插件注册机制

### 1. 策略插件注册

```ruby
# 在策略类中自动注册
class DraftSaveStrategy < ::Strategy::BaseStrategy
  strategy_for 'document', 'save', 'draft'
  
  def perform(params = {})
    # 策略实现
  end
end

# 或者通过 YAML 配置注册
# lib/dsl/config/strategy.yaml
strategies:
  - domain: document
    action: save
    context: draft
    class: Plugins::Strategy::Save::DraftSaveStrategy
```

### 2. 字段类型注册

```ruby
# 定义字段类型
class NumberRangeType < FieldType
  def initialize(name, options = {})
    super(name, :number_range, options)
  end
  
  def validate(value)
    # 自定义验证逻辑
  end
  
  def to_mongo(value)
    # 转换为 MongoDB 存储格式
  end
end

# 注册字段类型
FieldTypeRegistry.register(:number_range, NumberRangeType)
```

## 🛠️ 使用示例

### 在控制器中使用策略

```ruby
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

### 定义字段验证规则

```ruby
document_fields = [
  FieldType.new('title', :string, required: true, min_length: 3, max_length: 100),
  FieldType.new('price_range', :number_range, searchable: true),
  FieldType.new('status', :enum, values: ['draft', 'published', 'archived'], default: 'draft')
]

def validate_document(data, fields = document_fields)
  fields.each_with_object([]) do |field, errors|
    if data.key?(field.name)
      valid, message = field.validate(data[field.name])
      errors << message unless valid
    end
    errors
  end
end
```

## 🔄 集成与扩展

### 与现有系统集成

1. **与模型集成**：策略可以直接操作 MongoDB 模型
2. **与 UI 集成**：字段类型定义与 UI 组件系统结合
3. **与 API 集成**：在 Sinatra 控制器中使用策略模式

### 扩展方式

1. **新增策略**：创建新的策略类并注册
2. **新增字段类型**：扩展 `FieldType` 类支持新的数据类型
3. **自定义钩子**：通过 `before_execute` 和 `after_execute` 注入自定义逻辑

## 📌 最佳实践

1. **策略设计**：保持策略职责单一，遵循单一职责原则
2. **字段验证**：在策略和字段类型中都进行验证，确保数据一致性
3. **错误处理**：提供清晰的错误信息和错误码
4. **性能考虑**：对频繁访问的策略考虑实现缓存机制

