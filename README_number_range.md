# 数字范围字段测试

这个项目实现了一个自定义字段类型`NumberRangeField`，用于处理数字范围数据，并提供了相应的UI标签`number_range_input`。

## 功能特点

1. **后端处理**：
   - 在`NumberRangeField`类中实现了数字范围的处理逻辑
   - 支持数组格式`[min, max]`和哈希格式`{min: value, max: value}`
   - 提供了查询处理、数据库存取等功能

2. **前端标签**：
   - 实现了`number_range_input`标签，生成两个输入框用于输入最小值和最大值
   - 自动将输入值转换为JSON格式，便于后端处理
   - 支持设置默认值

## 如何测试

1. 安装依赖：
   ```
   gem install sinatra
   ```

2. 运行测试服务器：
   ```
   ruby test_server.rb
   ```

3. 在浏览器中访问：
   ```
   http://localhost:4567/
   ```

4. 在表单中输入数字范围，点击"提交"按钮，查看处理结果。

## 实现细节

1. **字段类型注册**：
   - 在`FieldRegistry`中注册了`number_range`字段类型

2. **标签注册**：
   - 在`TagLibraryKr`中注册了`number_range_input`标签

3. **UI实现**：
   - 在`KrTagHelper`中实现了`number_range_input`方法，生成相应的HTML和JavaScript代码

4. **后端处理**：
   - 在`NumberRangeField`中实现了数据处理和查询处理逻辑
