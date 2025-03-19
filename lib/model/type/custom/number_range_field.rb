# frozen_string_literal: true

require_relative '../builtin/field'

class NumberRangeField < Field
  attr_accessor :min_value, :max_value
  
  # 类方法：检查是否可以处理该字段
  def self.can_handle?(key, value)
    return false unless key.to_s.end_with?('_number_range')
    
    if value.is_a?(Array) && value.size == 2 && 
       value.all? { |v| v.is_a?(Numeric) || v.to_s.match?(/\A-?\d+(\.\d+)?\z/) }
      # 数组格式的数字范围
      return true
    elsif value.is_a?(Hash) && value[:min] && value[:max]
      # 对象格式的数字范围
      return true
    end
    
    false
  end
  
  # 类方法：处理字段数据
  def self.process_data(data, key, value)
    if value.is_a?(Array) && value.size == 2
      # 处理数组格式的数字范围
      begin
        # 创建字段实例
        field = self.new
        field.min_value = value[0].to_f
        field.max_value = value[1].to_f
        field.value = [field.min_value, field.max_value]
        
        # 更新数据
        data[key] = field.value
      rescue => e
        puts "处理数字范围数组错误: #{e.message}"
      end
    elsif value.is_a?(Hash) && value[:min] && value[:max]
      # 处理对象格式的数字范围
      begin
        # 创建字段实例
        field = self.new
        field.from_db(value)
        
        # 更新数据
        data[key] = field.value
      rescue => e
        puts "处理数字范围对象错误: #{e.message}"
      end
    end
  end
  
  # 类方法：检查是否能处理该查询
  def self.can_process_query?(field_key, query_value)
    return false unless field_key.to_s.end_with?('_number_range')
    return query_value.is_a?(Hash) && query_value.key?(:$numberRange)
  end
  
  # 类方法：处理数字范围查询
  def self.process_query(field_key, query_value)
    # 如果是我们自定义的 $numberRange 操作符，将其转换为 MongoDB 支持的操作符
    if query_value.is_a?(Hash) && query_value[:$numberRange].is_a?(Array) && query_value[:$numberRange].size == 2
      min_value = query_value[:$numberRange][0].to_f
      max_value = query_value[:$numberRange][1].to_f
      
      puts "[数字范围查询] 最小值: #{min_value}, 最大值: #{max_value}"
      
      # 创建数字范围查询条件，支持三种格式
      return {
        "$or" => [
          # 显式类型格式查询 (_type: 'number_range', value: [min, max])
          { "$and" => [
            { "#{field_key}._type" => "number_range" },
            { "#{field_key}.value.0" => { "$lte" => max_value } },  # 数据最小值 <= 查询最大值
            { "#{field_key}.value.1" => { "$gte" => min_value } }   # 数据最大值 >= 查询最小值
          ]},
          # 对象格式查询 (min: value, max: value)
          { "$and" => [
            { "#{field_key}.min" => { "$lte" => max_value } },   # 数据最小值 <= 查询最大值
            { "#{field_key}.max" => { "$gte" => min_value } }    # 数据最大值 >= 查询最小值
          ]},
          # 数组格式查询 ([min, max])
          { "$and" => [
            { "#{field_key}.0" => { "$lte" => max_value } },   # 数据最小值 <= 查询最大值
            { "#{field_key}.1" => { "$gte" => min_value } }    # 数据最大值 >= 查询最小值
          ]}
        ]
      }
    end
    
    # 如果不是我们自定义的操作符，直接返回原始查询条件
    return query_value
  end
  
  # 类方法：检查是否可以处理查询
  def self.can_process_query?(field_key, query_value)
    query_value.is_a?(Hash) && query_value[:$numberRange].is_a?(Array) && query_value[:$numberRange].size == 2
  end
  
  def initialize(options = {})
    super()
    @type = 'number_range'
    # 初始化其他属性
    options.each do |key, value|
      instance_variable_set("@#{key}", value) if respond_to?("#{key}=")
    end
  end
  
  # 验证数字范围
  def c_number_range
    return false if value.nil?
    return false unless value.is_a?(Array) && value.size == 2
    
    @min_value = value[0].to_f
    @max_value = value[1].to_f
    
    return @min_value <= @max_value
  end
  
  # 格式化为数据库存储格式
  def to_db
    return nil if value.nil?
    {
      min: @min_value,
      max: @max_value
    }
  end
  
  # 从数据库加载
  def from_db(db_value)
    return nil if db_value.nil?
    
    # 处理显式类型格式
    if db_value.is_a?(Hash) && db_value[:_type] == 'number_range' && db_value[:value].is_a?(Array) && db_value[:value].size == 2
      begin
        @min_value = db_value[:value][0].to_f
        @max_value = db_value[:value][1].to_f
        @value = [@min_value, @max_value]
        return self
      rescue => e
        puts "处理显式类型数字范围错误: #{e.message}"
      end
    end
    
    # 处理数组格式
    if db_value.is_a?(Array) && db_value.size == 2
      begin
        @min_value = db_value[0].to_f
        @max_value = db_value[1].to_f
        @value = [@min_value, @max_value]
        return self
      rescue => e
        puts "处理数组格式数字范围错误: #{e.message}"
      end
    end
    
    # 处理哈希表格式
    if db_value.is_a?(Hash) && (db_value[:min] || db_value[:max])
      begin
        @min_value = db_value[:min].to_f if db_value[:min]
        @max_value = db_value[:max].to_f if db_value[:max]
        @value = [@min_value, @max_value]
        return self
      rescue => e
        puts "处理哈希表格式数字范围错误: #{e.message}"
      end
    end
    
    puts "无法解析数字范围数据: #{db_value.inspect}"
    self
  end
  
  # 检查数字是否在范围内
  def contains?(number)
    return false if @min_value.nil? || @max_value.nil?
    
    num = number.to_f
    return num >= @min_value && num <= @max_value
  end
  
  # 获取范围中间值
  def median
    return nil if @min_value.nil? || @max_value.nil?
    (@min_value + @max_value) / 2.0
  end
  
  # 获取范围大小
  def range_size
    return nil if @min_value.nil? || @max_value.nil?
    @max_value - @min_value
  end
end
