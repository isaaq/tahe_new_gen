# frozen_string_literal: true

require_relative '../lib/model/type/field_registry'

# 测试日期范围字段
def test_date_range_field
  puts "测试日期范围字段："
  date_range = FieldRegistry.create_field('date_range')
  
  # 设置有效的日期范围
  date_range.value = ['2023-01-01', '2023-12-31']
  puts "有效日期范围验证: #{date_range.c_date_range}"
  
  # 设置无效的日期范围（开始日期晚于结束日期）
  date_range.value = ['2023-12-31', '2023-01-01']
  puts "无效日期范围验证: #{date_range.c_date_range}"
  
  # 检查日期是否在范围内
  date_range.value = ['2023-01-01', '2023-12-31']
  date_range.c_date_range
  puts "2023-06-15 在范围内: #{date_range.contains?('2023-06-15')}"
  puts "2024-01-01 在范围内: #{date_range.contains?('2024-01-01')}"
  
  # 数据库格式转换
  db_value = date_range.to_db
  puts "数据库格式: #{db_value}"
  
  # 从数据库加载
  new_date_range = FieldRegistry.create_field('date_range')
  new_date_range.from_db(db_value)
  puts "从数据库加载: #{new_date_range.value.inspect}"
end

# 测试坐标字段
def test_coordinate_field
  puts "\n测试坐标字段："
  coord = FieldRegistry.create_field('coordinate')
  
  # 设置有效的坐标
  coord.value = [39.9042, 116.4074] # 北京坐标
  puts "有效坐标验证: #{coord.c_coordinate}"
  
  # 设置无效的坐标
  coord.value = [100, 200] # 超出范围
  puts "无效坐标验证: #{coord.c_coordinate}"
  
  # 计算距离
  coord1 = FieldRegistry.create_field('coordinate')
  coord2 = FieldRegistry.create_field('coordinate')
  
  coord1.value = [39.9042, 116.4074] # 北京
  coord2.value = [31.2304, 121.4737] # 上海
  
  coord1.c_coordinate
  coord2.c_coordinate
  
  puts "北京到上海的距离: #{coord1.distance_to(coord2).round(2)} 公里"
  
  # 数据库格式转换
  db_value = coord1.to_db
  puts "数据库格式: #{db_value}"
end

# 测试数字范围字段
def test_number_range_field
  puts "\n测试数字范围字段："
  num_range = FieldRegistry.create_field('number_range')
  
  # 设置有效的数字范围
  num_range.value = [10, 20]
  puts "有效数字范围验证: #{num_range.c_number_range}"
  
  # 设置无效的数字范围
  num_range.value = [20, 10]
  puts "无效数字范围验证: #{num_range.c_number_range}"
  
  # 检查数字是否在范围内
  num_range.value = [10, 20]
  num_range.c_number_range
  puts "15 在范围内: #{num_range.contains?(15)}"
  puts "25 在范围内: #{num_range.contains?(25)}"
  
  # 获取范围中间值和大小
  puts "范围中间值: #{num_range.median}"
  puts "范围大小: #{num_range.range_size}"
end

# 运行测试
test_date_range_field
test_coordinate_field
test_number_range_field
