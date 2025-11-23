# 基于位置权限策略

## 基本信息

- **插件ID**: `strategy-permission-location-based`
- **分类**: `strategy/permission`
- **版本**: `1.0.0`
- **作者**: `kr_new_gen_team`

## 描述

基于地理位置控制权限，支持位置感知权限。

## 使用方法

### 基本用法

```ruby
strategy = Strategy.resolve(
  domain: 'permission',
  action: 'filter',
  context: 'location_based'
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

