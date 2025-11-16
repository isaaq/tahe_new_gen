# frozen_string_literal: true

# FilterBuilder - 智能Filter构建器
# 从查询参数构建MongoDB filter（参考老系统设计）
class FilterBuilder
  # 从查询参数构建 MongoDB filter
  def self.build_from_params(params)
    filter = {}
    
    params.each do |key, value|
      next if skip_param?(key)
      next if value.nil? || value == 'null' || value == ''
      
      # 1. 处理 OR 查询: "field1|field2=value" => { $or: [{field1: value}, {field2: value}] }
      if key.to_s.include?('|')
        or_conditions = key.to_s.split('|').map do |field|
          { field.to_sym => normalize_value(value) }
        end
        filter['$or'] = or_conditions
        next
      end
      
      # 2. 处理日期范围: "2024-01-01 - 2024-12-31"
      if value.is_a?(String) && value.include?(' - ')
        filter[key.to_sym] = parse_date_range(value)
        next
      end
      
      # 3. 处理 IN 查询: "value1,value2,value3"
      if value.is_a?(String) && value.include?(',') && !value.include?(' - ')
        values = value.split(',').map { |v| normalize_value(v.strip) }
        filter[key.to_sym] = { '$in': values }
        next
      end
      
      # 4. 处理正则匹配（模糊查询）
      if value.is_a?(String) && !value.empty?
        filter[key.to_sym] = /#{Regexp.escape(value)}/i
        next
      end
      
      # 5. 其他类型（数字、布尔）
      filter[key.to_sym] = normalize_value(value)
    end
    
    filter
  end
  
  private
  
  def self.skip_param?(key)
    # 跳过内部参数和路由参数
    internal_params = %w[
      _ collection page limit fk cond sort sub 
      table_name splat captures
    ]
    
    key_str = key.to_s
    key_str.start_with?('_') || internal_params.include?(key_str)
  end
  
  def self.normalize_value(value)
    return value unless value.is_a?(String)
    
    # ObjectId
    begin
      return BSON::ObjectId(value) if value =~ /^[0-9a-f]{24}$/i
    rescue
      # 不是合法的 ObjectId，继续
    end
    
    # 数字
    return value.to_i if value =~ /^\d+$/
    
    # 浮点数
    return value.to_f if value =~ /^\d+\.\d+$/
    
    # 布尔
    return true if value == 'true'
    return false if value == 'false'
    
    # 默认字符串
    value
  end
  
  def self.parse_date_range(range_str)
    start_str, end_str = range_str.split(' - ').map(&:strip)
    start_date = Date.parse(start_str)
    end_date = Date.parse(end_str)
    
    {
      '$gte': start_date.to_time.utc,
      '$lt': end_date.next_day.to_time.utc
    }
  rescue => e
    puts "⚠️  解析日期范围失败: #{range_str}, #{e.message}"
    range_str  # 解析失败，返回原值
  end
end




