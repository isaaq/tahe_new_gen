# 多索引查询策略

## 基本信息

- **插件ID**: `strategy-query-multi-index`
- **分类**: `strategy/query`
- **版本**: `1.0.0`
- **作者**: `kr_new_gen_team`

## 描述

支持多索引查询，跨多个索引查询数据。

## 使用方法

### 基本用法

```ruby
strategy = Strategy.resolve(
  domain: 'document',
  action: 'query',
  context: 'multi_index'
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

