#!/usr/bin/env ruby
# 测试自定义字段类型与MongoDB的集成

require 'minitest/autorun'
require 'date'
require_relative 'test_common'
require_relative '../lib/model/type/field_registry'
require_relative '../lib/model/type/custom/date_range_field'
require_relative '../lib/model/type/custom/coordinate_field'
require_relative '../lib/model/type/custom/number_range_field'

class TestCustomFieldsMongo < Minitest::Test
  def setup
    # 连接到测试数据库
    @db = Common::M[:test_custom_fields]
    # 清空测试集合
    @db.del_many({})
    
    # 为坐标字段创建地理空间索引
    begin
      # 直接使用MongoDB集合创建索引
      @db.db.collections.each do |coll|
        if coll.name == 'test_custom_fields'
          coll.indexes.create_one({ "location_coordinate" => "2dsphere" })
          break
        end
      end
    rescue => e
      puts "创建地理空间索引失败: #{e.message}"
    end
  end
  
  def teardown
    # 清空测试集合
    @db.del_many({})
  end
  
  def test_date_range_field
    # 创建测试数据
    test_data = {
      name: '测试日期范围',
      event_date_range: { _type: 'date_range', value: [Date.new(2025, 1, 1), Date.new(2025, 12, 31)] }
    }
    
    # 添加到数据库
    result = @db.add(test_data)
    assert result.inserted_id, '数据应该成功插入'
    
    # 查询并验证
    record = @db.query(_id: result.inserted_id).to_a.first
    puts "[测试日期范围] 查询结果: #{record.inspect}"
    
    # 验证字段格式
    assert record[:event_date_range], '应该有event_date_range字段'
    
    # 使用FieldRegistry处理数据
    field = DateRangeField.new
    field.from_db(record[:event_date_range])
    
    # 验证处理后的数据
    assert_equal 2, field.value.size, '日期范围应该有两个元素'
    assert_instance_of Date, field.value[0], '第一个元素应该是Date类型'
    assert_instance_of Date, field.value[1], '第二个元素应该是Date类型'
    assert_equal Date.new(2025, 1, 1), field.value[0], '开始日期应该正确'
    assert_equal Date.new(2025, 12, 31), field.value[1], '结束日期应该正确'
    
    # 测试日期范围查询
    query_result = @db.query(event_date_range: { '$dateRange': ['2025-06-01', '2025-06-30'] }).to_a
    assert_equal 1, query_result.size, '日期范围查询应该返回一条记录'
    
    # 测试日期不在范围内的查询
    query_result = @db.query(event_date_range: { '$dateRange': ['2026-01-01', '2026-12-31'] }).to_a
    assert_equal 0, query_result.size, '日期范围查询应该返回零条记录'
  end
  
  def test_coordinate_field
    # 创建测试数据
    test_data = {
      name: '测试坐标',
      location_coordinate: { type: 'Point', coordinates: [116.4074, 39.9042] } # 北京坐标，GeoJSON格式
    }
    
    # 添加到数据库
    result = @db.add(test_data)
    assert result.inserted_id, '数据应该成功插入'
    
    # 查询并验证
    record = @db.query(_id: result.inserted_id).to_a.first
    puts "[测试坐标] 查询结果: #{record.inspect}"
    
    # 验证字段格式
    assert record['location_coordinate'], '应该有location_coordinate字段'
    
    # 坐标字段可能已经被处理为数组格式
    if record['location_coordinate'].is_a?(Array)
      assert_equal 2, record['location_coordinate'].size, '坐标应该有两个元素'
    else
      # 如果还是GeoJSON格式
      assert record['location_coordinate']['type'], '应该有type字段'
      assert record['location_coordinate']['coordinates'], '应该有coordinates字段'
      assert_equal 'Point', record['location_coordinate']['type'], '类型应该是Point'
      assert_equal 2, record['location_coordinate']['coordinates'].size, '坐标应该有两个元素'
    end
    
    # 使用CoordinateField处理数据
    field = CoordinateField.new
    
    # 如果已经是数组格式，直接设置值
    if record['location_coordinate'].is_a?(Array)
      field.value = record['location_coordinate']
    else
      # 如果还是GeoJSON格式，使用from_db处理
      field.from_db(record['location_coordinate'])
    end
    
    # 验证处理后的数据
    assert_equal 2, field.value.size, '坐标应该有两个元素'
    assert_instance_of Float, field.value[0], '第一个元素应该是Float类型'
    assert_instance_of Float, field.value[1], '第二个元素应该是Float类型'
    assert_in_delta 39.9042, field.value[0], 0.0001, '纬度应该正确'
    assert_in_delta 116.4074, field.value[1], 0.0001, '经度应该正确'
    
    # 测试地理位置查询 - 使用记录ID确保只返回一条记录
    query_result = @db.query(
      "$and" => [
        { "_id": result.inserted_id },  # 使用刚刚插入的记录ID
        { location_coordinate: { 
            '$nearSphere': { 
              '$geometry': { 
                type: 'Point', 
                coordinates: [116.4, 39.9] 
              },
              '$maxDistance': 10000 # 10公里，单位是米
            }
          }
        }  
      ]
    ).to_a
    assert_equal 1, query_result.size, '地理位置查询应该返回一条记录'
    
    # 测试地理位置不在范围内的查询 - 使用记录ID确保查询正确性
    query_result = @db.query(
      "$and" => [
        { "_id": result.inserted_id },  # 使用刚刚插入的记录ID
        { location_coordinate: { 
            '$nearSphere': { 
              '$geometry': { 
                type: 'Point', 
                coordinates: [114.0579, 22.5431] 
              },
              '$maxDistance': 100 # 100米，距离太远不应该匹配
            }
          }
        }  
      ]
    ).to_a
    assert_equal 0, query_result.size, '地理位置查询应该返回零条记录'
  end
  
  def test_number_range_field
    # 创建测试数据
    test_data = {
      name: '测试数字范围',
      price_number_range: { _type: 'number_range', value: [100, 500] }
    }
    
    # 添加到数据库
    result = @db.add(test_data)
    assert result.inserted_id, '数据应该成功插入'
    
    # 查询并验证
    record = @db.query(_id: result.inserted_id).to_a.first
    puts "[测试数字范围] 查询结果: #{record.inspect}"
    
    # 验证字段格式
    assert record[:price_number_range], '应该有price_number_range字段'
    
    # 使用NumberRangeField处理数据
    field = NumberRangeField.new
    field.from_db(record[:price_number_range])
    
    # 验证处理后的数据
    assert_equal 2, field.value.size, '数字范围应该有两个元素'
    assert_instance_of Float, field.value[0], '第一个元素应该是Float类型'
    assert_instance_of Float, field.value[1], '第二个元素应该是Float类型'
    assert_in_delta 100.0, field.value[0], 0.0001, '最小值应该正确'
    assert_in_delta 500.0, field.value[1], 0.0001, '最大值应该正确'
    
    # 测试数字范围查询 - 使用记录ID确保只返回一条记录
    query_result = @db.query(
      "$and" => [
        { "_id": result.inserted_id },  # 使用刚刚插入的记录ID
        { "price_number_range._type" => "number_range" },
        { "$and" => [
          { "price_number_range.value.0" => { "$lte" => 300 } },  # 数据最小值 <= 查询最大值
          { "price_number_range.value.1" => { "$gte" => 200 } }   # 数据最大值 >= 查询最小值
        ]}
      ]
    ).to_a
    assert_equal 1, query_result.size, '数字范围查询应该返回一条记录'
    
    # 测试数字不在范围内的查询 - 使用记录ID确保查询正确性
    query_result = @db.query(
      "$and" => [
        { "_id": result.inserted_id },  # 使用刚刚插入的记录ID
        { "price_number_range._type" => "number_range" },
        { "$and" => [
          { "price_number_range.value.0" => { "$lte" => 1000 } },  # 数据最小值 <= 查询最大值
          { "price_number_range.value.1" => { "$gte" => 600 } }    # 数据最大值 >= 查询最小值
        ]}
      ]
    ).to_a
    # 因为范围不匹配，应该返回0条记录
    assert_equal 0, query_result.size, '数字范围查询应该返回零条记录'
  end
  
  def test_update_custom_fields
    # 创建测试数据
    test_data = {
      name: '测试更新',
      event_date_range: { _type: 'date_range', value: [Date.new(2025, 1, 1), Date.new(2025, 6, 30)] },
      location_coordinate: { type: 'Point', coordinates: [116.4074, 39.9042] },
      price_number_range: { _type: 'number_range', value: [100, 300] }
    }
    
    # 添加到数据库
    result = @db.add(test_data)
    assert result.inserted_id, '数据应该成功插入'
    
    # 更新数据
    update_data = {
      event_date_range: { _type: 'date_range', value: [Date.new(2025, 7, 1), Date.new(2025, 12, 31)] },
      location_coordinate: { type: 'Point', coordinates: [121.4737, 31.2304] }, # 上海坐标，GeoJSON格式
      price_number_range: { _type: 'number_range', value: [400, 600] }
    }
    
    @db.update({ _id: result.inserted_id }, { '$set': update_data })
    
    # 查询并验证
    record = @db.query(_id: result.inserted_id).to_a.first
    
    # 验证日期范围更新
    assert record[:event_date_range], '应该有event_date_range字段'
    date_field_update = DateRangeField.new
    date_field_update.from_db(record[:event_date_range])
    assert_equal Date.new(2025, 7, 1), date_field_update.value[0], '开始日期应该已更新'
    assert_equal Date.new(2025, 12, 31), date_field_update.value[1], '结束日期应该已更新'
    
    # 验证坐标更新
    assert record[:location_coordinate], '应该有location_coordinate字段'
    coord_field_update = CoordinateField.new
    coord_field_update.from_db(record[:location_coordinate])
    assert_in_delta 31.2304, coord_field_update.value[0], 0.0001, '纬度应该已更新'
    assert_in_delta 121.4737, coord_field_update.value[1], 0.0001, '经度应该已更新'
    
    # 验证数字范围更新
    assert record[:price_number_range], '应该有price_number_range字段'
    num_field_update = NumberRangeField.new
    num_field_update.from_db(record[:price_number_range])
    assert_in_delta 400.0, num_field_update.value[0], 0.0001, '最小值应该已更新'
    assert_in_delta 600.0, num_field_update.value[1], 0.0001, '最大值应该已更新'
  end
  
  def test_complex_document_with_custom_fields
    # 创建包含嵌套自定义字段的复杂文档
    test_data = {
      name: '复杂文档测试',
      main_event: {
        title: '主要事件',
        period_date_range: { _type: 'date_range', value: [Date.new(2025, 1, 1), Date.new(2025, 12, 31)] },
        venue_coordinate: { type: 'Point', coordinates: [116.4074, 39.9042] }
      },
      sub_events: [
        {
          title: '子事件1',
          period_date_range: { _type: 'date_range', value: [Date.new(2025, 3, 1), Date.new(2025, 3, 15)] },
          venue_coordinate: { type: 'Point', coordinates: [121.4737, 31.2304] },
          budget_number_range: { _type: 'number_range', value: [1000, 5000] }
        },
        {
          title: '子事件2',
          period_date_range: { _type: 'date_range', value: [Date.new(2025, 6, 1), Date.new(2025, 6, 15)] },
          venue_coordinate: { type: 'Point', coordinates: [114.0579, 22.5431] },
          budget_number_range: { _type: 'number_range', value: [2000, 8000] }
        }
      ]
    }
    
    # 添加到数据库
    result = @db.add(test_data)
    assert result.inserted_id, '数据应该成功插入'
    
    # 查询并验证
    record = @db.query(_id: result.inserted_id).to_a.first
    puts "[测试复杂文档] 查询结果: #{record.inspect}"
    
    # 验证主事件
    assert_equal '主要事件', record[:main_event][:title], '主事件标题应该正确'
    
    # 验证主事件日期范围
    assert record[:main_event][:period_date_range], '应该有period_date_range字段'
    date_field = DateRangeField.new
    date_field.from_db(record[:main_event][:period_date_range])
    assert_equal Date.new(2025, 1, 1), date_field.value[0], '主事件开始日期应该正确'
    assert_equal Date.new(2025, 12, 31), date_field.value[1], '主事件结束日期应该正确'
    
    # 验证主事件坐标
    assert record[:main_event][:venue_coordinate], '应该有venue_coordinate字段'
    coord_field = CoordinateField.new
    coord_field.from_db(record[:main_event][:venue_coordinate])
    assert_in_delta 39.9042, coord_field.value[0], 0.0001, '主事件纬度应该正确'
    assert_in_delta 116.4074, coord_field.value[1], 0.0001, '主事件经度应该正确'
    
    # 验证子事件
    assert_equal 2, record[:sub_events].size, '应该有两个子事件'
    
    # 验证子事件1
    assert_equal '子事件1', record[:sub_events][0][:title], '子事件1标题应该正确'
    
    # 验证子事件1日期范围
    assert record[:sub_events][0][:period_date_range], '应该有period_date_range字段'
    date_field1 = DateRangeField.new
    date_field1.from_db(record[:sub_events][0][:period_date_range])
    assert_equal Date.new(2025, 3, 1), date_field1.value[0], '子事件1开始日期应该正确'
    assert_equal Date.new(2025, 3, 15), date_field1.value[1], '子事件1结束日期应该正确'
    
    # 验证子事件1坐标
    assert record[:sub_events][0][:venue_coordinate], '应该有venue_coordinate字段'
    coord_field1 = CoordinateField.new
    coord_field1.from_db(record[:sub_events][0][:venue_coordinate])
    assert_in_delta 31.2304, coord_field1.value[0], 0.0001, '子事件1纬度应该正确'
    assert_in_delta 121.4737, coord_field1.value[1], 0.0001, '子事件1经度应该正确'
    
    # 验证子事件1数字范围
    assert record[:sub_events][0][:budget_number_range], '应该有budget_number_range字段'
    num_field1 = NumberRangeField.new
    num_field1.from_db(record[:sub_events][0][:budget_number_range])
    assert_in_delta 1000.0, num_field1.value[0], 0.0001, '子事件1预算最小值应该正确'
    assert_in_delta 5000.0, num_field1.value[1], 0.0001, '子事件1预算最大值应该正确'
    
    # 验证子事件2
    assert_equal '子事件2', record[:sub_events][1][:title], '子事件2标题应该正确'
    
    # 验证子事件2日期范围
    assert record[:sub_events][1][:period_date_range], '应该有period_date_range字段'
    date_field2 = DateRangeField.new
    date_field2.from_db(record[:sub_events][1][:period_date_range])
    assert_equal Date.new(2025, 6, 1), date_field2.value[0], '子事件2开始日期应该正确'
    assert_equal Date.new(2025, 6, 15), date_field2.value[1], '子事件2结束日期应该正确'
    
    # 验证子事件2坐标
    assert record[:sub_events][1][:venue_coordinate], '应该有venue_coordinate字段'
    coord_field2 = CoordinateField.new
    coord_field2.from_db(record[:sub_events][1][:venue_coordinate])
    assert_in_delta 22.5431, coord_field2.value[0], 0.0001, '子事件2纬度应该正确'
    assert_in_delta 114.0579, coord_field2.value[1], 0.0001, '子事件2经度应该正确'
    
    # 验证子事件2数字范围
    assert record[:sub_events][1][:budget_number_range], '应该有budget_number_range字段'
    num_field2 = NumberRangeField.new
    num_field2.from_db(record[:sub_events][1][:budget_number_range])
    assert_in_delta 2000.0, num_field2.value[0], 0.0001, '子事件2预算最小值应该正确'
    assert_in_delta 8000.0, num_field2.value[1], 0.0001, '子事件2预算最大值应该正确'
  end
end
