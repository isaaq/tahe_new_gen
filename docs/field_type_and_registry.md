# 字段类型(FieldType)与字段注册表(FieldRegistry)详解

## 1. 核心概念

### 1.1 字段类型(FieldType)

字段类型定义了字段的行为特性，包括：
- 字段值的验证规则
- 数据格式转换（如：序列化/反序列化）
- 字段的元数据和业务规则

### 1.2 字段注册表(FieldRegistry)

字段注册表是一个中心化的注册中心，负责：
- 管理字段类型的注册和查找
- 提供字段类型的创建和实例化
- 维护类型名称到具体实现的映射

## 2. 主要区别

| 特性 | FieldType | FieldRegistry |
|------|-----------|---------------|
| 职责 | 定义字段行为 | 管理字段类型 |
| 抽象层次 | 业务逻辑层 | 基础设施层 |
| 关注点 | 字段的"是什么" | 类型的"如何管理" |
| 使用场景 | 业务逻辑处理 | 类型注册和实例化 |

## 3. 代码示例

### 3.1 字段类型定义

```ruby
# 自定义数字范围字段类型
class NumberRangeField < FieldType
  def initialize(options = {})
    @min = options[:min]
    @max = options[:max]
  end

  def validate(value)
    return [false, "值不能为空"] if value.nil?
    return [false, "值必须大于等于 #{@min}"] if @min && value < @min
    return [false, "值必须小于等于 #{@max}"] if @max && value > @max
    [true, nil]
  end
  
  def to_mongo(value)
    # 转换为MongoDB存储格式
    { min: @min, max: @max, value: value }
  end
  
  def from_mongo(value)
    # 从MongoDB格式解析
    value.is_a?(Hash) ? value[:value] : value
  end
end
```

### 3.2 字段类型注册

```ruby
# 注册自定义类型
FieldRegistry.register('number_range', NumberRangeField)

# 创建字段实例
field = FieldRegistry.create_field('number_range', min: 0, max: 100)

# 使用字段实例
result, error = field.validate(50)  # => [true, nil]
result, error = field.validate(150) # => [false, "值必须小于等于 100"]
```

## 4. 设计模式解析

### 4.1 FieldType 与策略模式

FieldType 使用了策略模式，允许在运行时选择不同的验证和转换逻辑：

```ruby
# 不同的字段类型实现不同的验证逻辑
class EmailField < FieldType
  def validate(value)
    # 邮箱格式验证
  end
end

class PhoneField < FieldType
  def validate(value)
    # 手机号格式验证
  end
end
```

### 4.2 FieldRegistry 与注册表模式

FieldRegistry 使用注册表模式，提供全局访问点：

```ruby
class FieldRegistry
  @@field_types = {}
  
  def self.register(type_name, field_class)
    @@field_types[type_name.to_s] = field_class
  end
  
  def self.get_type(type_name)
    @@field_types[type_name.to_s] || Field
  end
end
```

## 5. 实际应用场景

### 5.1 动态表单字段

```ruby
# 动态创建表单字段
def create_form_field(field_config)
  field_type = field_config[:type] || 'text'
  options = field_config[:options] || {}
  
  FieldRegistry.create_field(field_type, options)
end

# 使用示例
field_configs = [
  { name: 'username', type: 'text', options: { required: true } },
  { name: 'age', type: 'number_range', options: { min: 0, max: 120 } },
  { name: 'email', type: 'email' }
]

form_fields = field_configs.map { |config| create_form_field(config) }
```

### 5.2 数据导入导出

```ruby
# 数据导入
def import_data(row, field_definitions)
  data = {}
  
  field_definitions.each do |field_def|
    field = FieldRegistry.create_field(field_def[:type], field_def[:options])
    value = row[field_def[:name]]
    
    # 验证字段值
    valid, error = field.validate(value)
    raise "字段 #{field_def[:name]} 验证失败: #{error}" unless valid
    
    # 转换并存储
    data[field_def[:name]] = field.to_mongo(value)
  end
  
  data
end
```

## 6. 最佳实践

### 6.1 字段类型设计

1. **保持单一职责**：每个字段类型只负责一种数据类型的处理
2. **提供默认值**：为必填字段提供合理的默认值
3. **完整的验证**：实现全面的验证逻辑
4. **类型转换**：处理好各种边界情况

### 6.2 注册表使用

1. **初始化时注册**：在应用启动时注册所有字段类型
2. **使用常量**：为字段类型名称定义常量，避免硬编码
3. **错误处理**：处理未注册类型的情况
4. **线程安全**：确保注册表的线程安全性

## 7. 扩展性考虑

### 7.1 添加新字段类型

1. 创建新的 FieldType 子类
2. 实现必要的接口方法
3. 在系统启动时注册新类型

### 7.2 动态加载

```ruby
# 自动加载字段类型
def load_field_types(directory)
  Dir.glob(File.join(directory, '**/*.rb')).each do |file|
    require file
  end
  
  # 调用注册方法
  FieldType.descendants.each do |type_class|
    type_class.register if type_class.respond_to?(:register)
  end
end
```

## 8. 总结

- **FieldType** 负责定义字段的具体行为，是业务逻辑的载体
- **FieldRegistry** 负责管理字段类型的生命周期，是基础设施的一部分
- 两者配合使用，可以实现灵活、可扩展的字段类型系统
- 通过组合使用设计模式，使系统更易于维护和扩展
