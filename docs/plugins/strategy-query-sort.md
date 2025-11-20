# 排序查询策略

## 基本信息

- **插件ID**: `strategy-query-sort`
- **分类**: `strategy/query`
- **版本**: `1.0.0`
- **作者**: `kr_new_gen_team`

## 描述

支持多字段排序查询，可指定升序或降序。

## 使用方法

### 基本用法

```ruby
strategy = Strategy.resolve(
  domain: 'document',
  action: 'query',
  context: 'sort'
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

