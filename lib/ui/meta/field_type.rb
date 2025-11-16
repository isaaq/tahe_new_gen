module UI
  module Meta
    class FieldType
      attr_reader :name, :type, :options
      
      VALID_TYPES = [
        :string, :text, :integer, :float, :boolean, :date, :datetime,
        :enum, :array, :object, :reference, :file, :image, :number_range
      ]
      
      def initialize(name, type, options = {})
        @name = name.to_s
        @type = validate_type(type)
        @options = default_options.merge(options)
      end
      
      def required?
        !!@options[:required]
      end
      
      def searchable?
        !!@options[:searchable]
      end
      
      def validate(value)
        # 必填验证
        if required? && (value.nil? || value.to_s.empty?)
          return [false, "#{@name} 不能为空"]
        end
        
        # 正则验证
        if @options[:pattern] && !value.to_s.match?(@options[:pattern])
          return [false, "#{@name} 格式不正确"]
        end
        
        # 类型特定验证
        case @type
        when :integer, :float
          # 数值范围验证
          if @options[:min] && value.to_f < @options[:min]
            return [false, "#{@name} 不能小于 #{@options[:min]}"]
          end
          
          if @options[:max] && value.to_f > @options[:max]
            return [false, "#{@name} 不能大于 #{@options[:max]}"]
          end
        when :string, :text
          # 字符串长度验证
          if @options[:min_length] && value.to_s.length < @options[:min_length]
            return [false, "#{@name} 长度不能小于 #{@options[:min_length]}"]
          end
          
          if @options[:max_length] && value.to_s.length > @options[:max_length]
            return [false, "#{@name} 长度不能超过 #{@options[:max_length]}"]
          end
        when :enum
          # 枚举值验证
          if @options[:values] && !@options[:values].include?(value)
            return [false, "#{@name} 必须是以下值之一: #{@options[:values].join(', ')}"]
          end
        when :number_range
          # 数值范围验证
          if value.is_a?(Hash) && (value[:min] || value[:max])
            if value[:min] && value[:max] && value[:min] > value[:max]
              return [false, "#{@name} 的最小值不能大于最大值"]
            end
          else
            return [false, "#{@name} 必须包含 min 或 max 值"]
          end
        end
        
        [true, nil]
      end
      
      def to_mongo(value)
        # 将字段值转换为适合 MongoDB 存储的格式
        case @type
        when :date
          value.is_a?(Date) ? value : Date.parse(value.to_s)
        when :datetime
          value.is_a?(Time) ? value : Time.parse(value.to_s)
        when :integer
          value.to_i
        when :float
          value.to_f
        when :boolean
          !!value
        else
          value
        end
      rescue StandardError => _error
        # 转换失败时返回原值
        value
      end
      
      private
      
      def validate_type(type)
        type = type.to_sym
        raise "无效的字段类型: #{type}" unless VALID_TYPES.include?(type)
        type
      end
      
      def default_options
        {
          required: false,
          searchable: false,
          system: false,
          description: ""
        }
      end
    end
  end
end
