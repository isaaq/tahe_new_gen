# 自定义通知策略

## 基本信息

- **插件ID**: `strategy-notification-custom`
- **分类**: `strategy/notification`
- **版本**: `1.0.0`
- **作者**: `kr_new_gen_team`

## 描述

支持自定义通知渠道，可扩展新的通知方式。

## 使用方法

### 基本用法

```ruby
strategy = Strategy.resolve(
  domain: 'notification',
  action: 'notify',
  context: 'custom'
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

