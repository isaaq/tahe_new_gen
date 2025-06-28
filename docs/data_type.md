# 业务数据类型文档

## 目录结构
```
lib/
└── model/
    └── type/
        ├── _config.rb              # 配置
        ├── builtin/                # 内建字段类型
        │   ├── _config.rb         
        │   ├── enum.rb           # 枚举类型
        │   ├── field.rb           # 字段基类
        │   ├── field_behavior.rb  # 字段行为
        │   └── text.rb            # 文本类型
        │
        ├── common_type.rb         # 通用类型
        │
        ├── custom/                # 自定义字段类型
        │   ├── coordinate_field.rb    # 坐标字段
        │   ├── date_range_field.rb    # 日期范围字段
        │   └── number_range_field.rb  # 数字范围字段
        │
        ├── data/                   # 数据文件
        │   ├── 名字.txt
        │   └── 姓.txt
        │
        ├── field_registry.rb      # 字段注册表
        ├── t_name.rb               # 名称类型
        └── t_user.rb               # 用户类型
```

## 内建字段类型 (Built-in Types)

| 类型 | 说明 | 对应文件 |
|------|------|----------|
| choice_field | 选择字段 | builtin/choice_field.rb |
| text_field | 文本字段 | builtin/text_field.rb |

## 自定义字段类型 (Custom Types)

| 类型 | 说明 | 对应文件 |
|------|------|----------|
| coordinate_field | 坐标字段 | custom/coordinate_field.rb |
| date_range_field | 日期范围字段 | custom/date_range_field.rb |
| number_range_field | 数字范围字段 | custom/number_range_field.rb |

## 核心组件

- **field_registry.rb**: 字段类型注册表，用于管理所有可用的字段类型
- **common_type.rb**: 定义通用类型和基础行为
- **_config.rb**: 类型系统配置文件

## 数据文件

- `data/名字.txt`: 名字数据
- `data/姓.txt`: 姓氏数据

## 与数据项的绑定规则

以NumberRangeField为例，在当前的代码实现中， 与数据的绑定是通过以下几个机制实现的：

### 1. 字段名称约定

```ruby
def self.can_handle?(key, value)
  return false unless key.to_s.end_with?('_number_range')
  # ...其他判断条件...
end
```

- 当字段名以 `_number_range` 结尾时，会自动使用 `NumberRangeField` 处理该字段
- 这是一种约定大于配置的方式，简化了字段类型的指定

### 2. 字段注册系统

在 `FieldRegistry` 中注册字段类型：

```ruby
# 在 field_registry.rb 中
register('number_range', NumberRangeField)
```

### 3. 数据处理流程

#### 数据写入时：
1. 通过 `FieldRegistry.process_field` 处理字段数据
2. 根据字段名和值自动选择合适的字段类型
3. 调用对应字段类型的 `process_data` 方法

#### 数据读取时：
1. 通过 `from_db` 方法从数据库加载数据
2. 将原始数据转换为字段对象

### 4. 数据验证流程
1. 在数据保存前进行格式验证
2. 确保数据符合字段类型的约束条件
3. 验证失败时抛出相应的异常