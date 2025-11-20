# 插件商店使用示例 - 完整操作步骤

## 📋 示例场景

假设我们需要实现一个"产品管理"功能，需要：
1. 保存产品数据（支持草稿保存）
2. 验证产品信息（价格、库存等）
3. 产品发布后发送通知
4. 支持产品图片上传

让我们一步步使用插件商店来实现这个功能。

---

## 步骤1：浏览和搜索插件

### 1.1 使用Ruby代码浏览插件

```ruby
# 加载必要的库
require_relative 'lib/plugins/store/plugin_store'
require_relative 'lib/ai_services/plugin_assistant'

# 获取插件商店实例
store = PluginStore.instance

# 列出所有保存策略插件
puts "=== 保存策略插件 ==="
save_plugins = store.list_plugins(category: 'strategy/save')
save_plugins.each do |plugin|
  puts "- #{plugin[:name]} (#{plugin[:plugin_id]})"
  puts "  描述: #{plugin[:description]}"
end

# 输出示例：
# === 保存策略插件 ===
# - 草稿保存策略 (strategy-save-draft)
#   描述: 保存草稿数据，不触发发布流程
# - 批量保存策略 (strategy-save-batch)
#   描述: 批量保存多个文档
# ...
```

### 1.2 使用API浏览插件

```bash
# 列出所有保存策略插件
curl "http://localhost:4567/api/plugin-store/list?category=strategy/save"

# 搜索"草稿"相关的插件
curl "http://localhost:4567/api/plugin-store/search?keyword=草稿"
```

### 1.3 使用AI推荐插件

```ruby
# 获取AI助手实例
assistant = PluginAssistant.instance

# 描述需求，让AI推荐插件
requirement = "我需要保存产品数据，支持草稿保存，保存后需要验证，发布后要发送通知"

puts "=== AI推荐插件 ==="
result = assistant.recommend_plugins(requirement)

if result[:success]
  result[:plugins].each do |plugin|
    puts "- #{plugin[:name]} (#{plugin[:plugin_id]})"
    puts "  推荐度: #{plugin[:confidence]}"
    puts "  原因: #{plugin[:reason]}"
  end
else
  puts "推荐失败: #{result[:error]}"
end
```

---

## 步骤2：查看插件详情

### 2.1 获取插件详细信息

```ruby
# 查看草稿保存策略的详细信息
plugin = store.get_plugin('strategy-save-draft')

puts "=== 插件详情 ==="
puts "插件ID: #{plugin[:plugin_id]}"
puts "名称: #{plugin[:name]}"
puts "分类: #{plugin[:category]}"
puts "版本: #{plugin[:version]}"
puts "描述: #{plugin[:description]}"
puts "标签: #{plugin[:tags].join(', ')}"
puts "是否内置: #{plugin[:is_builtin]}"

# 查看配置schema
if plugin[:config_schema]
  puts "\n配置选项:"
  puts plugin[:config_schema].to_yaml
end

# 查看使用示例
if plugin[:examples] && plugin[:examples].any?
  puts "\n使用示例:"
  plugin[:examples].each do |example|
    puts example
  end
end
```

### 2.2 使用API获取插件详情

```bash
# 获取插件详情
curl "http://localhost:4567/api/plugin-store/strategy-save-draft"
```

---

## 步骤3：安装插件

### 3.1 安装单个插件

```ruby
# 安装草稿保存策略
puts "=== 安装插件 ==="
result = store.install_plugin('strategy-save-draft', '1.0.0')

if result[:success]
  puts "✅ 插件安装成功！"
  puts "安装路径: #{result[:installed_path]}"
  puts "配置文件已更新: #{result[:config_updated]}"
else
  puts "❌ 安装失败: #{result[:error]}"
end
```

### 3.2 使用API安装插件

```bash
# 安装插件
curl -X POST "http://localhost:4567/api/plugin-store/install" \
  -H "Content-Type: application/json" \
  -d '{
    "plugin_id": "strategy-save-draft",
    "version": "1.0.0"
  }'
```

### 3.3 批量安装插件（使用AI推荐组合）

```ruby
# 使用AI推荐插件组合
requirements = [
  "保存产品数据，支持草稿",
  "验证产品价格和库存",
  "发布后发送通知",
  "支持图片上传"
]

puts "=== AI推荐插件组合 ==="
combination = assistant.suggest_plugin_combination(requirements)

if combination[:success]
  puts "推荐的插件组合:"
  combination[:plugins].each_with_index do |plugin, index|
    puts "#{index + 1}. #{plugin[:name]} (#{plugin[:plugin_id]})"
  end
  
  puts "\n安装顺序:"
  combination[:install_order].each_with_index do |plugin_id, index|
    puts "#{index + 1}. #{plugin_id}"
  end
  
  # 按顺序安装
  puts "\n开始安装插件..."
  combination[:install_order].each do |plugin_id|
    result = store.install_plugin(plugin_id)
    if result[:success]
      puts "✅ #{plugin_id} 安装成功"
    else
      puts "❌ #{plugin_id} 安装失败: #{result[:error]}"
    end
  end
end
```

---

## 步骤4：配置插件

### 4.1 使用AI配置向导

```ruby
# 使用AI辅助配置插件
puts "=== AI配置向导 ==="
user_input = "保存时自动添加创建时间，保存到products集合"

result = assistant.configure_plugin(
  'strategy-save-draft',
  user_input
)

if result[:success]
  puts "生成的配置:"
  puts result[:config].to_yaml
  
  # 应用配置
  if result[:apply_config]
    puts "\n配置已自动应用"
  end
else
  puts "配置失败: #{result[:error]}"
end
```

### 4.2 手动配置插件

```yaml
# lib/dsl/config/strategy.yaml
strategies:
  - domain: product
    action: save
    context: draft
    class: Plugins::Strategy::Save::DraftSaveStrategy
    config:
      collection: products
      auto_timestamp: true
      fields:
        - name
        - price
        - stock
```

---

## 步骤5：使用插件

### 5.1 在代码中使用策略插件

```ruby
# 在控制器中使用保存策略
require_relative 'lib/dsl/strategy'

class ProductController
  def save_draft(product_data)
    # 根据domain、action、context选择策略
    strategy = Strategy.resolve(
      domain: 'product',
      action: 'save',
      context: 'draft'
    )
    
    # 执行策略
    result = strategy.execute(
      data: product_data,
      context: {
        user_id: current_user.id,
        collection: 'products'
      }
    )
    
    if result[:success]
      puts "产品草稿保存成功: #{result[:document_id]}"
      return result
    else
      puts "保存失败: #{result[:error]}"
      return nil
    end
  end
end
```

### 5.2 使用字段类型插件

```ruby
# 定义产品字段，使用字段类型插件
product_fields = [
  {
    name: 'name',
    type: 'text',
    required: true,
    plugins: ['field-validation-plugin']
  },
  {
    name: 'price',
    type: 'amount',
    required: true,
    plugins: ['field-validation-plugin', 'field-format-plugin'],
    validation: {
      min: 0,
      max: 999999
    }
  },
  {
    name: 'stock',
    type: 'number',
    required: true,
    plugins: ['field-validation-plugin'],
    validation: {
      min: 0,
      integer: true
    }
  },
  {
    name: 'image',
    type: 'image',
    plugins: ['field-upload-plugin']
  }
]
```

### 5.3 使用表单行为插件

```ruby
# 在表单中使用行为插件
form_config = {
  fields: product_fields,
  behaviors: [
    {
      plugin: 'form-behavior-field-linkage',
      config: {
        rules: [
          {
            source: 'category',
            target: 'tags',
            mapping: {
              '电子产品' => ['电子', '数码'],
              '服装' => ['时尚', '服饰']
            }
          }
        ]
      }
    },
    {
      plugin: 'form-behavior-auto-fill',
      config: {
        rules: [
          {
            field: 'created_at',
            value: 'now'
          }
        ]
      }
    }
  ]
}
```

---

## 步骤6：查看已安装的插件

### 6.1 列出已安装的插件

```ruby
# 获取所有已安装的插件
installed = store.list_plugins(installed: true)

puts "=== 已安装的插件 ==="
installed.each do |plugin|
  puts "- #{plugin[:name]} (#{plugin[:plugin_id]})"
  puts "  版本: #{plugin[:version]}"
  puts "  安装时间: #{plugin[:installed_at]}"
end
```

### 6.2 使用API查看已安装插件

```bash
# 获取已安装插件列表
curl "http://localhost:4567/api/plugin-store/installed"
```

---

## 步骤7：完整示例 - 产品管理功能实现

### 7.1 完整的Ruby脚本示例

```ruby
#!/usr/bin/env ruby
# frozen_string_literal: true

# 产品管理功能完整示例
require_relative 'lib/plugins/store/plugin_store'
require_relative 'lib/ai_services/plugin_assistant'
require_relative 'lib/dsl/strategy'

class ProductManager
  def initialize
    @store = PluginStore.instance
    @assistant = PluginAssistant.instance
  end
  
  # 步骤1: 推荐和安装插件
  def setup_plugins
    puts "=" * 60
    puts "步骤1: 推荐和安装插件"
    puts "=" * 60
    
    requirement = "产品管理：保存草稿、验证数据、发布通知、图片上传"
    result = @assistant.recommend_plugins(requirement)
    
    if result[:success]
      puts "\n推荐的插件:"
      result[:plugins].each do |plugin|
        puts "  - #{plugin[:name]}"
        
        # 安装插件
        install_result = @store.install_plugin(plugin[:plugin_id])
        if install_result[:success]
          puts "    ✅ 安装成功"
        else
          puts "    ❌ 安装失败: #{install_result[:error]}"
        end
      end
    end
  end
  
  # 步骤2: 配置插件
  def configure_plugins
    puts "\n" + "=" * 60
    puts "步骤2: 配置插件"
    puts "=" * 60
    
    # 配置保存策略
    config_result = @assistant.configure_plugin(
      'strategy-save-draft',
      '保存到products集合，自动添加时间戳'
    )
    
    if config_result[:success]
      puts "✅ 保存策略配置完成"
      puts "配置内容:"
      puts config_result[:config].to_yaml
    end
  end
  
  # 步骤3: 保存产品草稿
  def save_product_draft(product_data)
    puts "\n" + "=" * 60
    puts "步骤3: 保存产品草稿"
    puts "=" * 60
    
    # 获取保存策略
    strategy = Strategy.resolve(
      domain: 'product',
      action: 'save',
      context: 'draft'
    )
    
    # 执行保存
    result = strategy.execute(
      data: product_data,
      context: {
        collection: 'products',
        user_id: 'user123'
      }
    )
    
    if result[:success]
      puts "✅ 产品草稿保存成功"
      puts "文档ID: #{result[:document_id]}"
      return result[:document_id]
    else
      puts "❌ 保存失败: #{result[:error]}"
      return nil
    end
  end
  
  # 步骤4: 验证产品数据
  def validate_product(product_data)
    puts "\n" + "=" * 60
    puts "步骤4: 验证产品数据"
    puts "=" * 60
    
    # 获取验证策略
    strategy = Strategy.resolve(
      domain: 'product',
      action: 'validate',
      context: 'form'
    )
    
    # 执行验证
    result = strategy.execute(data: product_data)
    
    if result[:success]
      puts "✅ 验证通过"
      return true
    else
      puts "❌ 验证失败:"
      result[:errors].each do |error|
        puts "  - #{error[:field]}: #{error[:message]}"
      end
      return false
    end
  end
  
  # 步骤5: 发布产品
  def publish_product(product_id)
    puts "\n" + "=" * 60
    puts "步骤5: 发布产品"
    puts "=" * 60
    
    # 获取发布策略
    strategy = Strategy.resolve(
      domain: 'product',
      action: 'submit',
      context: 'publish'
    )
    
    # 执行发布
    result = strategy.execute(
      document_id: product_id,
      context: {
        notify: true,
        channels: ['email', 'sms']
      }
    )
    
    if result[:success]
      puts "✅ 产品发布成功"
      puts "通知已发送"
      return true
    else
      puts "❌ 发布失败: #{result[:error]}"
      return false
    end
  end
  
  # 主流程
  def run
    # 示例产品数据
    product_data = {
      name: 'iPhone 15 Pro',
      price: 8999,
      stock: 100,
      category: '电子产品',
      description: '最新款iPhone',
      image: 'https://example.com/iphone15.jpg'
    }
    
    # 执行完整流程
    setup_plugins
    configure_plugins
    
    # 验证数据
    if validate_product(product_data)
      # 保存草稿
      product_id = save_product_draft(product_data)
      
      if product_id
        # 发布产品
        publish_product(product_id)
      end
    end
    
    puts "\n" + "=" * 60
    puts "流程完成！"
    puts "=" * 60
  end
end

# 运行示例
if __FILE__ == $0
  manager = ProductManager.new
  manager.run
end
```

### 7.2 运行示例

```bash
# 运行完整示例
ruby examples/product_manager_example.rb
```

输出示例：
```
============================================================
步骤1: 推荐和安装插件
============================================================

推荐的插件:
  - 草稿保存策略
    ✅ 安装成功
  - 表单验证策略
    ✅ 安装成功
  - 邮件通知策略
    ✅ 安装成功
  - 图片上传插件
    ✅ 安装成功

============================================================
步骤2: 配置插件
============================================================
✅ 保存策略配置完成
配置内容:
collection: products
auto_timestamp: true

============================================================
步骤3: 保存产品草稿
============================================================
✅ 产品草稿保存成功
文档ID: 507f1f77bcf86cd799439011

============================================================
步骤4: 验证产品数据
============================================================
✅ 验证通过

============================================================
步骤5: 发布产品
============================================================
✅ 产品发布成功
通知已发送

============================================================
流程完成！
============================================================
```

---

## 步骤8：使用API的完整示例

### 8.1 使用curl的完整流程

```bash
#!/bin/bash

echo "=== 步骤1: 搜索插件 ==="
curl "http://localhost:4567/api/plugin-store/search?keyword=保存"

echo -e "\n=== 步骤2: 获取插件详情 ==="
curl "http://localhost:4567/api/plugin-store/strategy-save-draft"

echo -e "\n=== 步骤3: 安装插件 ==="
curl -X POST "http://localhost:4567/api/plugin-store/install" \
  -H "Content-Type: application/json" \
  -d '{
    "plugin_id": "strategy-save-draft",
    "version": "1.0.0"
  }'

echo -e "\n=== 步骤4: AI推荐插件 ==="
curl -X POST "http://localhost:4567/api/plugin-store/recommend" \
  -H "Content-Type: application/json" \
  -d '{
    "requirement": "我需要保存产品数据"
  }'

echo -e "\n=== 步骤5: 查看已安装插件 ==="
curl "http://localhost:4567/api/plugin-store/installed"
```

### 8.2 使用JavaScript的完整流程

```javascript
// 产品管理功能 - JavaScript示例
const API_BASE = 'http://localhost:4567/api/plugin-store';

// 步骤1: 搜索插件
async function searchPlugins(keyword) {
  const response = await fetch(`${API_BASE}/search?keyword=${keyword}`);
  const plugins = await response.json();
  console.log('搜索结果:', plugins);
  return plugins;
}

// 步骤2: 获取插件详情
async function getPluginDetails(pluginId) {
  const response = await fetch(`${API_BASE}/${pluginId}`);
  const plugin = await response.json();
  console.log('插件详情:', plugin);
  return plugin;
}

// 步骤3: 安装插件
async function installPlugin(pluginId, version = '1.0.0') {
  const response = await fetch(`${API_BASE}/install`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ plugin_id: pluginId, version })
  });
  const result = await response.json();
  console.log('安装结果:', result);
  return result;
}

// 步骤4: AI推荐插件
async function recommendPlugins(requirement) {
  const response = await fetch(`${API_BASE}/recommend`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ requirement })
  });
  const result = await response.json();
  console.log('AI推荐:', result);
  return result;
}

// 步骤5: 查看已安装插件
async function getInstalledPlugins() {
  const response = await fetch(`${API_BASE}/installed`);
  const plugins = await response.json();
  console.log('已安装插件:', plugins);
  return plugins;
}

// 完整流程
async function setupProductManagement() {
  console.log('=== 开始设置产品管理功能 ===');
  
  // 1. AI推荐插件
  const recommendation = await recommendPlugins(
    '产品管理：保存草稿、验证数据、发布通知'
  );
  
  // 2. 安装推荐的插件
  if (recommendation.success) {
    for (const plugin of recommendation.plugins) {
      await installPlugin(plugin.plugin_id);
    }
  }
  
  // 3. 查看已安装的插件
  const installed = await getInstalledPlugins();
  
  console.log('=== 设置完成 ===');
  return installed;
}

// 运行
setupProductManagement();
```

---

## 📝 总结

这个示例展示了：

1. ✅ **浏览和搜索插件** - 找到需要的插件
2. ✅ **查看插件详情** - 了解插件功能和配置
3. ✅ **安装插件** - 将插件安装到系统中
4. ✅ **配置插件** - 使用AI或手动配置插件
5. ✅ **使用插件** - 在代码中调用插件功能
6. ✅ **查看已安装插件** - 管理已安装的插件

通过这些步骤，你可以快速构建完整的产品管理功能，而无需编写大量重复代码！

---

**提示**：
- 所有插件都有详细的文档，查看 `docs/plugins/` 目录
- 使用AI推荐可以快速找到合适的插件组合
- 插件可以组合使用，实现复杂的功能需求


