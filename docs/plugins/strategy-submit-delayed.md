# 延迟发布策略

## 基本信息

- **插件ID**: `strategy-submit-delayed`
- **分类**: `strategy/submit`
- **版本**: `1.0.0`
- **作者**: `kr_new_gen_team`

## 描述

提交后延迟指定时间后发布，支持倒计时。

## 使用方法

### 基本用法

```ruby
strategy = Strategy.resolve(
  domain: 'document',
  action: 'submit',
  context: 'delayed'
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

