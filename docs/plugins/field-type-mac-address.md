# MAC地址字段类型

## 基本信息

- **插件ID**: `field-type-mac-address`
- **分类**: `field_type/business`
- **版本**: `1.0.0`
- **作者**: `kr_new_gen_team`

## 描述

MAC地址字段类型，支持MAC地址验证。

## 使用方法

### 基本用法

```ruby
field = MacAddressFieldType.new('field_name', {
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

