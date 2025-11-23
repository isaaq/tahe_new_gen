# 外部验证策略

## 基本信息

- **插件ID**: `strategy-validation-external`
- **分类**: `strategy/validation`
- **版本**: `1.0.0`
- **作者**: `kr_new_gen_team`

## 描述

调用外部服务进行验证，支持第三方验证。

## 使用方法

### 基本用法

```ruby
strategy = Strategy.resolve(
  domain: 'validation',
  action: 'validate',
  context: 'external'
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

