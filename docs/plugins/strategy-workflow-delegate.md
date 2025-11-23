# 委托策略

## 基本信息

- **插件ID**: `strategy-workflow-delegate`
- **分类**: `strategy/workflow`
- **版本**: `1.0.0`
- **作者**: `kr_new_gen_team`

## 描述

委托任务给其他处理人，支持任务委托。

## 使用方法

### 基本用法

```ruby
strategy = Strategy.resolve(
  domain: 'workflow',
  action: 'process',
  context: 'delegate'
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

