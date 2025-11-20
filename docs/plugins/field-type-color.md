# 颜色字段类型

## 基本信息

- **插件ID**: `field-type-color`
- **分类**: `field_type/composite`
- **版本**: `1.0.0`
- **作者**: `kr_new_gen_team`

## 描述

颜色字段类型，支持颜色选择器和十六进制输入。

## 使用方法

### 基本用法

```ruby
field = ColorFieldType.new('field_name', {
  required: true,
  # 其他选项
})

valid, error = field.validate(value)
```

### 配置选项

无配置选项

## 示例

暂无示例

## API参考

### 方法

- `validate(value)`: 验证字段值
- `to_mongo(value)`: 转换为MongoDB格式
- `from_mongo(value)`: 从MongoDB格式转换
- `to_ui(value)`: 转换为UI显示格式

