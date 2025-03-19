# frozen_string_literal: true

require_relative '../builtin/field'

class CoordinateField < Field
  attr_accessor :latitude, :longitude
  
  # 类方法：检查是否可以处理该字段
  def self.can_handle?(key, value)
    return false unless key.to_s.end_with?('_coordinate')
    
    if value.is_a?(Array) && value.size == 2 && value.all? { |v| v.is_a?(Numeric) || v.to_s.match?(/\A-?\d+(\.\d+)?\z/) }
      # 数组格式的坐标
      return true
    elsif value.is_a?(Hash) && value[:type] == 'Point' && value[:coordinates].is_a?(Array)
      # GeoJSON格式的坐标
      return true
    end
    
    false
  end
  
  # 类方法：处理字段数据
  def self.process_data(data, key, value)
    if value.is_a?(Array) && value.size == 2
      # 处理数组格式的坐标
      begin
        # 创建字段实例
        field = self.new
        field.latitude = value[0].to_f
        field.longitude = value[1].to_f
        field.value = [field.latitude, field.longitude]
        
        # 更新数据
        data[key] = field.value
      rescue => e
        puts "处理坐标数组错误: #{e.message}"
      end
    elsif value.is_a?(Hash) && value[:type] == 'Point' && value[:coordinates].is_a?(Array)
      # 处理GeoJSON格式的坐标
      begin
        # 创建字段实例
        field = self.new
        field.from_db(value)
        
        # 更新数据
        data[key] = field.value
      rescue => e
        puts "处理GeoJSON坐标错误: #{e.message}"
      end
    end
  end
  
  # 类方法：检查是否能处理该查询
  def self.can_process_query?(field_key, query_value)
    return false unless field_key.to_s.end_with?('_coordinate')
    return query_value.is_a?(Hash) && query_value.key?(:$near)
  end
  
  # 类方法：处理坐标查询
  def self.process_query(field_key, query_value)
    return nil unless can_process_query?(field_key, query_value)
    
    coord = query_value[:$near]
    return nil unless coord.is_a?(Array) && coord.size >= 2
    
    begin
      # 纬度和经度
      lat = coord[0].to_f
      lng = coord[1].to_f
      
      # 转换为MongoDB地理空间查询
      geo_query = {
        :$nearSphere => {
          :$geometry => {
            :type => 'Point',
            :coordinates => [lng, lat] # MongoDB需要[经度, 纬度]格式
          }
        }
      }
      
      # 添加最大距离（如果提供）
      if coord.size > 2
        # 转换公里为米（MongoDB使用米作为单位）
        geo_query[:$nearSphere][:$maxDistance] = coord[2].to_f * 1000
      end
      
      # 创建包含地理查询的最终查询
      final_query = {}
      final_query[field_key] = geo_query
      
      return final_query
    rescue => e
      puts "坐标查询处理错误: #{e.message}"
      return nil
    end
  end
  
  def initialize(options = {})
    super()
    @type = 'coordinate'
    # 初始化其他属性
    options.each do |key, value|
      instance_variable_set("@#{key}", value) if respond_to?("#{key}=")
    end
  end
  
  # 验证坐标
  def c_coordinate
    return false if value.nil?
    return false unless value.is_a?(Array) && value.size == 2
    
    @latitude = value[0].to_f
    @longitude = value[1].to_f
    
    # 验证经纬度范围
    return false if @latitude < -90 || @latitude > 90
    return false if @longitude < -180 || @longitude > 180
    
    true
  end
  
  # 格式化为数据库存储格式
  def to_db
    return nil if value.nil?
    
    # 确保经纬度已经设置
    if @latitude.nil? || @longitude.nil?
      if value.is_a?(Array) && value.size == 2
        @latitude = value[0].to_f
        @longitude = value[1].to_f
      end
    end
    
    # 返回GeoJSON格式
    {
      type: 'Point',
      coordinates: [@longitude, @latitude]
    }
  end
  
  # 从数据库加载
  def from_db(db_value)
    return nil if db_value.nil?
    
    # 处理GeoJSON格式（支持符号键和字符串键）
    if db_value.is_a?(Hash)
      type_value = db_value[:type] || db_value['type']
      coordinates = db_value[:coordinates] || db_value['coordinates']
      
      if type_value == 'Point' && coordinates.is_a?(Array) && coordinates.size == 2
        @longitude = coordinates[0]
        @latitude = coordinates[1]
        @value = [@latitude, @longitude]
        return self
      end
    end
    
    # 处理普通数组格式
    if db_value.is_a?(Array) && db_value.size == 2
      if db_value[0].is_a?(Numeric) && db_value[1].is_a?(Numeric)
        # 假设数组格式为 [latitude, longitude]
        @latitude = db_value[0]
        @longitude = db_value[1]
        @value = [@latitude, @longitude]
        return self
      end
    end
    
    # 处理显式类型格式（支持符号键和字符串键）
    if db_value.is_a?(Hash)
      value_array = db_value[:value] || db_value['value']
      
      if value_array.is_a?(Array) && value_array.size == 2
        @latitude = value_array[0]
        @longitude = value_array[1]
        @value = [@latitude, @longitude]
        return self
      end
    end
    
    puts "无法解析坐标数据: #{db_value.inspect}"
    self
  end
  
  # 计算与另一个坐标的距离（公里）
  def distance_to(other_coord)
    return nil unless other_coord.is_a?(CoordinateField)
    
    # 使用Haversine公式计算球面距离
    earth_radius = 6371 # 地球半径(公里)
    
    lat1_rad = @latitude * Math::PI / 180
    lat2_rad = other_coord.latitude * Math::PI / 180
    
    delta_lat = (other_coord.latitude - @latitude) * Math::PI / 180
    delta_lon = (other_coord.longitude - @longitude) * Math::PI / 180
    
    a = Math.sin(delta_lat/2) * Math.sin(delta_lat/2) +
        Math.cos(lat1_rad) * Math.cos(lat2_rad) *
        Math.sin(delta_lon/2) * Math.sin(delta_lon/2)
    
    c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a))
    
    earth_radius * c
  end
end
