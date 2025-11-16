# 加密保存策略

## 基本信息

- **插件ID**: `strategy-save-encrypted`
- **分类**: `strategy/save`
- **版本**: `1.0.0`
- **作者**: `kr_new_gen_team`

## 描述

保存文档时自动加密敏感字段，提高数据安全性。

## 使用方法

### 基本用法

```ruby
strategy = Strategy.resolve(
  domain: 'document',
  action: 'save',
  context: 'encrypted'
)

result = strategy.execute(
  data: { /* 数据 */ },
  collection: 'documents'
)
```

### 配置选项

无配置选项

## 示例

暂无示例

## API参考

### 方法

- `before_execute(params)`: 执行前钩子
- `perform(params)`: 执行策略逻辑
- `after_execute(params, result)`: 执行后钩子

