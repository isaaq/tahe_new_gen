# 业务数据

## 结构
```text
lib/
└── model/
    └── type/
        ├── _config.rb
        ├── builtin/
        │   ├── _config.rb
        │   ├── enum.rb
        │   ├── field.rb
        │   ├── field_behavior.rb
        │   └── text.rb
        ├── common_type.rb
        ├── custom/
        │   ├── coordinate_field.rb
        │   ├── date_range_field.rb
        │   └── number_range_field.rb
        ├── data/
        │   ├── 名字.txt
        │   └── 姓.txt
        ├── field_registry.rb
        ├── t_name.rb
        └── t_user.rb
```

## builtin 内建
    choice_field    选择字段
    text_field      文本字段


## custom 自定义
    coordinate_field    坐标字段
    date_range_field    日期范围字段
    number_range_field  数字范围字段
