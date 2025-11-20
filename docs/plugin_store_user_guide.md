# 插件商店使用指南

## 📚 目录

1. [快速开始](#快速开始)
2. [插件分类](#插件分类)
3. [API使用](#api使用)
4. [AI辅助功能](#ai辅助功能)
5. [插件开发](#插件开发)
6. [常见问题](#常见问题)

## 🚀 快速开始

### 1. 浏览插件

```ruby
# 获取插件商店实例
store = PluginStore.instance

# 列出所有插件
all_plugins = store.list_plugins

# 按分类筛选
save_plugins = store.list_plugins(category: 'strategy/save')

# 按标签筛选
validation_plugins = store.list_plugins(tags: ['validation'])

# 搜索插件
results = store.search_plugins('保存')
```

### 2. 安装插件

```ruby
# 安装插件
result = store.install_plugin('strategy-save-draft', '1.0.0')

if result[:success]
  puts "插件安装成功！"
else
  puts "安装失败：#{result[:error]}"
end
```

### 3. 使用AI推荐

```ruby
# 获取AI助手实例
assistant = PluginAssistant.instance

# 推荐插件
recommendations = assistant.recommend_plugins('我需要一个保存草稿的功能')

recommendations[:plugins].each do |plugin|
  puts "- #{plugin[:name]}: #{plugin[:description]}"
end
```

## 📦 插件分类

### 策略插件（160个）

#### 保存策略（20个）
- `strategy-save-draft` - 草稿保存
- `strategy-save-batch` - 批量保存
- `strategy-save-async` - 异步保存
- `strategy-save-version` - 版本保存
- `strategy-save-encrypted` - 加密保存
- ... 更多请查看 [策略插件列表](../lib/plugins/strategy/)

#### 查询策略（30个）
- `strategy-query-pagination` - 分页查询
- `strategy-query-fulltext` - 全文搜索
- `strategy-query-fuzzy` - 模糊查询
- `strategy-query-geospatial` - 地理空间查询
- ... 更多请查看 [查询策略列表](../lib/plugins/strategy/query/)

#### 权限策略（25个）
- `strategy-permission-store-isolation` - 门店隔离
- `strategy-permission-role-based` - 角色权限
- `strategy-permission-data` - 数据权限
- `strategy-permission-attribute-based` - 基于属性权限
- ... 更多请查看 [权限策略列表](../lib/plugins/strategy/permission/)

### 字段类型插件（85个）

#### 基础类型（10个）
- `field-type-text` - 文本字段
- `field-type-number` - 数字字段
- `field-type-date` - 日期字段
- `field-type-boolean` - 布尔字段
- ... 更多请查看 [基础类型列表](../lib/plugins/field_type/basic/)

#### 业务类型（30个）
- `field-type-phone` - 手机号
- `field-type-email` - 邮箱
- `field-type-id-card` - 身份证
- `field-type-bank-card` - 银行卡
- ... 更多请查看 [业务类型列表](../lib/plugins/field_type/business/)

### 表单行为插件（33个）

- `form-behavior-field-linkage` - 字段联动
- `form-behavior-auto-fill` - 自动填充
- `form-behavior-field-validation` - 字段验证
- `form-behavior-field-format` - 字段格式化
- ... 更多请查看 [表单行为插件列表](../lib/plugins/other/form/behavior/)

### UI组件插件（50个）

- `ui-component-table` - 表格组件
- `ui-component-form` - 表单组件
- `ui-component-chart` - 图表组件
- `ui-component-button` - 按钮组件
- ... 更多请查看 [UI组件插件列表](../lib/plugins/other/ui_component/)

### 操作钩子插件（29个）

- `hook-before-save` - 保存前钩子
- `hook-after-save` - 保存后钩子
- `hook-before-update` - 更新前钩子
- `hook-on-error` - 错误处理钩子
- ... 更多请查看 [操作钩子插件列表](../lib/plugins/other/hook/)

### AI Prompt插件（30个）

- `ai-prompt-form-generation` - 表单生成
- `ai-prompt-code-generation` - 代码生成
- `ai-prompt-api-doc` - API文档生成
- `ai-prompt-query-optimization` - 查询优化
- ... 更多请查看 [AI Prompt插件列表](../lib/plugins/other/ai_prompt/)

### 数据源插件（20个）

- `data-source-mongodb` - MongoDB数据源
- `data-source-mysql` - MySQL数据源
- `data-source-api` - API数据源
- `data-source-redis` - Redis数据源
- ... 更多请查看 [数据源插件列表](../lib/plugins/data_source/)

## 🔌 API使用

### RESTful API端点

#### 1. 列出插件
```http
GET /api/plugin-store/list?category=strategy/save&tags=validation
```

#### 2. 搜索插件
```http
GET /api/plugin-store/search?keyword=保存
```

#### 3. 获取插件详情
```http
GET /api/plugin-store/strategy-save-draft
```

#### 4. 安装插件
```http
POST /api/plugin-store/install
Content-Type: application/json

{
  "plugin_id": "strategy-save-draft",
  "version": "1.0.0"
}
```

#### 5. 卸载插件
```http
POST /api/plugin-store/uninstall
Content-Type: application/json

{
  "plugin_id": "strategy-save-draft"
}
```

#### 6. 获取已安装插件
```http
GET /api/plugin-store/installed
```

## 🤖 AI辅助功能

### 1. 插件推荐

```http
POST /api/plugin-store/recommend
Content-Type: application/json

{
  "requirement": "我需要一个保存草稿的功能"
}
```

响应示例：
```json
{
  "success": true,
  "plugins": [
    {
      "plugin_id": "strategy-save-draft",
      "name": "草稿保存策略",
      "description": "...",
      "confidence": 0.95
    }
  ]
}
```

### 2. AI配置向导

```http
POST /api/plugin-store/configure
Content-Type: application/json

{
  "plugin_id": "strategy-save-draft",
  "user_input": "保存时自动添加时间戳"
}
```

### 3. 插件组合推荐

```http
POST /api/plugin-store/combine
Content-Type: application/json

{
  "requirements": [
    "保存数据",
    "验证数据",
    "发送通知"
  ]
}
```

## 🛠️ 插件开发

### 插件结构

```ruby
module Plugins
  module Strategy
    module Save
      class DraftSaveStrategy
        def execute(data:, context: {})
          # 插件逻辑
        end
      end
    end
  end
end
```

### 生成新插件

```ruby
# 使用批量生成器
require_relative 'lib/plugins/store/generate_plugins'

# 运行生成脚本
ruby -r ./lib/plugins/store/generate_plugins.rb -e "GeneratePlugins.run!"
```

### 插件元数据

```ruby
{
  plugin_id: "strategy-save-draft",
  name: "草稿保存策略",
  category: "strategy/save",
  version: "1.0.0",
  author: "your_name",
  description: "保存草稿数据",
  tags: ["save", "draft"],
  config_schema: {
    # 配置schema
  }
}
```

## ❓ 常见问题

### Q: 如何查找特定功能的插件？

A: 使用搜索功能：
```ruby
store.search_plugins('保存')
```

或使用AI推荐：
```ruby
assistant.recommend_plugins('我需要保存功能')
```

### Q: 插件安装后如何使用？

A: 策略插件会自动注册到StrategyRegistry，可以通过配置使用：
```yaml
# lib/dsl/config/strategy.yaml
strategies:
  - domain: document
    action: save
    context: draft
    class: Plugins::Strategy::Save::DraftSaveStrategy
```

### Q: 如何开发自定义插件？

A: 参考现有插件模板，创建插件文件，然后运行元数据生成脚本。

### Q: 插件如何更新？

A: 当前版本支持通过重新安装来更新插件。未来版本将支持版本管理和自动更新。

## 📖 相关文档

- [插件商店实现总结](./plugin_store_completion_final.md)
- [插件生成器实现](./plugin_generator_implementation.md)
- [插件策略实现](./kr_new_gen_plugin_strategy_impl.md)
- [插件商店UI指南](./plugin_store_ui_guide.md)

## 🎯 最佳实践

1. **使用AI推荐**：不确定需要哪个插件时，使用AI推荐功能
2. **查看文档**：每个插件都有详细的文档，查看 `docs/plugins/` 目录
3. **测试插件**：安装前先查看插件的测试用例
4. **组合使用**：多个插件可以组合使用，实现复杂功能
5. **版本管理**：注意插件的版本，确保兼容性

---

**最后更新**：2025-11-18  
**插件总数**：407个


