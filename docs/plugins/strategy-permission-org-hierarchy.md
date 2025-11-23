# 组织层级联动权限策略

## 基本信息

- **插件ID**: `strategy-permission-org-hierarchy`
- **分类**: `strategy/permission`
- **版本**: `1.0.0`
- **作者**: `kr_new_gen_team`

## 描述

基于组织层级的权限控制，支持上下级数据联动访问。

## 使用方法

### 基本用法

```ruby
strategy = Strategy.resolve(
  domain: 'permission',
  action: 'filter',
  context: 'org_hierarchy'
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

