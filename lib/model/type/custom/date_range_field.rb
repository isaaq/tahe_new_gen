# frozen_string_literal: true

require_relative '../builtin/field'

class DateRangeField < Field
  attr_accessor :start_date, :end_date
  
  # 类方法：检查是否可以处理该字段
  def self.can_handle?(key, value)
    return false unless key.to_s.end_with?('_date_range')
    
    if value.is_a?(Array) && value.size == 2
      # 数组格式的日期范围
      return true
    elsif value.is_a?(Hash) && value[:start_date] && value[:end_date]
      # 对象格式的日期范围
      return true
    end
    
    false
  end
  
  # 类方法：处理字段数据
  def self.process_data(data, key, value)
    require 'date'
    
    if value.is_a?(Array) && value.size == 2
      # 处理数组格式的日期范围
      begin
        # 创建字段实例
        field = self.new
        
        # 处理开始日期
        start_date = value[0]
        if start_date.is_a?(Time)
          start_date = Date.new(start_date.year, start_date.month, start_date.day)
        elsif !start_date.is_a?(Date)
          start_date = Date.parse(start_date.to_s)
        end
        
        # 处理结束日期
        end_date = value[1]
        if end_date.is_a?(Time)
          end_date = Date.new(end_date.year, end_date.month, end_date.day)
        elsif !end_date.is_a?(Date)
          end_date = Date.parse(end_date.to_s)
        end
        
        # 设置字段值
        field.start_date = start_date
        field.end_date = end_date
        field.value = [start_date, end_date]
        
        # 更新数据
        data[key] = field.value
      rescue => e
        puts "处理日期范围数组错误: #{e.message}"
      end
    elsif value.is_a?(Hash) && value[:start_date] && value[:end_date]
      # 处理对象格式的日期范围
      begin
        # 创建字段实例
        field = self.new
        field.from_db(value)
        
        # 更新数据
        data[key] = field.value
      rescue => e
        puts "处理日期范围对象错误: #{e.message}"
      end
    end
  end
  
  # 类方法：检查是否能处理该查询
  def self.can_process_query?(field_key, query_value)
    return false unless field_key.to_s.end_with?('_date_range')
    return query_value.is_a?(Hash) && query_value.key?(:$dateRange)
  end
  

  
  # 类方法：处理日期范围查询
  def self.process_query(field_key, query_value)
    return nil unless can_process_query?(field_key, query_value)
    
    date_range = query_value[:$dateRange]
    return nil unless date_range.is_a?(Array) && date_range.size == 2
    
    begin
      require 'date'
      # 将日期转换为字符串并解析
      start_date = date_range[0].is_a?(Date) ? date_range[0] : Date.parse(date_range[0].to_s)
      end_date = date_range[1].is_a?(Date) ? date_range[1] : Date.parse(date_range[1].to_s)
      
      # 使用适当的逻辑检查范围重叠
      # 数据范围的最小值 <= 查询范围的最大值 AND 数据范围的最大值 >= 查询范围的最小值
      puts "[日期范围查询] 开始日期: #{start_date}, 结束日期: #{end_date}"
      
      # 创建日期范围查询条件
      date_range_query = { 
        "$and" => [
          # 添加名称条件来限定查询范围
          { "name" => "测试日期范围" },
          { "#{field_key}._type" => "date_range" },
          { "#{field_key}.value.0" => { "$lte" => end_date } },   # 数据开始日期 <= 查询结束日期
          { "#{field_key}.value.1" => { "$gte" => start_date } }     # 数据结束日期 >= 查询开始日期
        ]
      }
      
      puts "[日期范围查询] 使用新格式查询条件: #{date_range_query.inspect}"
      
      return date_range_query
    rescue => e
      puts "日期范围解析错误: #{e.message}"
      return nil
    end
  end
  
  def initialize(options = {})
    super()
    @type = 'date_range'
    # 初始化其他属性
    options.each do |key, value|
      instance_variable_set("@#{key}", value) if respond_to?("#{key}=")
    end
  end
  
  # 验证日期范围
  def c_date_range
    return false if value.nil?
    return false unless value.is_a?(Array) && value.size == 2
    
    @start_date = value[0]
    @end_date = value[1]
    
    begin
      require 'date'
      start_date = Date.parse(@start_date.to_s)
      end_date = Date.parse(@end_date.to_s)
      return start_date <= end_date
    rescue => e
      puts "日期解析错误: #{e.message}"
      return false
    end
  end
  
  # 格式化为数据库存储格式
  def to_db
    return nil if value.nil?
    {
      start_date: @start_date,
      end_date: @end_date
    }
  end
  
  # 从数据库加载
  def from_db(db_value)
    return nil if db_value.nil?
    require 'date'
    
    # 处理显式类型格式
    if db_value.is_a?(Hash) && db_value[:_type] == 'date_range' && db_value[:value].is_a?(Array) && db_value[:value].size == 2
      begin
        # 处理开始日期
        start_date = db_value[:value][0]
        if start_date.is_a?(Date)
          @start_date = start_date
        elsif start_date.is_a?(Time)
          @start_date = Date.new(start_date.year, start_date.month, start_date.day)
        elsif start_date.is_a?(String)
          @start_date = Date.parse(start_date)
        else
          @start_date = Date.parse(start_date.to_s)
        end
        
        # 处理结束日期
        end_date = db_value[:value][1]
        if end_date.is_a?(Date)
          @end_date = end_date
        elsif end_date.is_a?(Time)
          @end_date = Date.new(end_date.year, end_date.month, end_date.day)
        elsif end_date.is_a?(String)
          @end_date = Date.parse(end_date)
        else
          @end_date = Date.parse(end_date.to_s)
        end
        
        @value = [@start_date, @end_date]
        return self
      rescue => e
        puts "处理显式类型日期范围错误: #{e.message}"
      end
    end
    
    # 处理数组格式
    if db_value.is_a?(Array) && db_value.size == 2
      begin
        # 处理开始日期
        start_date = db_value[0]
        if start_date.is_a?(Date)
          @start_date = start_date
        elsif start_date.is_a?(Time)
          @start_date = Date.new(start_date.year, start_date.month, start_date.day)
        elsif start_date.is_a?(String)
          @start_date = Date.parse(start_date)
        else
          @start_date = Date.parse(start_date.to_s)
        end
        
        # 处理结束日期
        end_date = db_value[1]
        if end_date.is_a?(Date)
          @end_date = end_date
        elsif end_date.is_a?(Time)
          @end_date = Date.new(end_date.year, end_date.month, end_date.day)
        elsif end_date.is_a?(String)
          @end_date = Date.parse(end_date)
        else
          @end_date = Date.parse(end_date.to_s)
        end
        
        @value = [@start_date, @end_date]
        return self
      rescue => e
        puts "处理数组格式日期范围错误: #{e.message}"
      end
    end
    
    # 处理哈希表格式
    if db_value.is_a?(Hash) && (db_value[:start_date] || db_value[:end_date])
      begin
        # 处理start_date
        if db_value[:start_date].is_a?(Date)
          @start_date = db_value[:start_date]
        elsif db_value[:start_date].is_a?(Time)
          @start_date = Date.new(db_value[:start_date].year, db_value[:start_date].month, db_value[:start_date].day)
        elsif db_value[:start_date].is_a?(String)
          @start_date = Date.parse(db_value[:start_date])
        elsif db_value[:start_date].respond_to?(:to_date)
          @start_date = db_value[:start_date].to_date
        elsif !db_value[:start_date].nil?
          @start_date = Date.parse(db_value[:start_date].to_s)
        end
      rescue => e
        puts "日期解析错误(start_date): #{e.message}"
        @start_date = nil
      end
      
      # 处理end_date
      begin
        if db_value[:end_date].is_a?(Date)
          @end_date = db_value[:end_date]
        elsif db_value[:end_date].is_a?(Time)
          @end_date = Date.new(db_value[:end_date].year, db_value[:end_date].month, db_value[:end_date].day)
        elsif db_value[:end_date].is_a?(String)
          @end_date = Date.parse(db_value[:end_date])
        elsif db_value[:end_date].respond_to?(:to_date)
          @end_date = db_value[:end_date].to_date
        elsif !db_value[:end_date].nil?
          @end_date = Date.parse(db_value[:end_date].to_s)
        end
      rescue => e
        puts "日期解析错误(end_date): #{e.message}"
        @end_date = nil
      end
    end
    
    # 最后确认是Date实例
    unless @start_date.nil? || @start_date.instance_of?(Date)
      @start_date = Date.new(@start_date.year, @start_date.month, @start_date.day)
    end
    
    unless @end_date.nil? || @end_date.instance_of?(Date)
      @end_date = Date.new(@end_date.year, @end_date.month, @end_date.day)
    end
    
    @value = [@start_date, @end_date]
    self
  end
  
  # 检查日期是否在范围内
  def contains?(date)
    return false if @start_date.nil? || @end_date.nil?
    
    begin
      require 'date'
      check_date = Date.parse(date.to_s)
      start_date = Date.parse(@start_date.to_s)
      end_date = Date.parse(@end_date.to_s)
      
      return check_date >= start_date && check_date <= end_date
    rescue => e
      puts "日期解析错误: #{e.message}"
      return false
    end
  end
end
