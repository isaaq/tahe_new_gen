class Meta
  attr_accessor :type, :parser

  def match_meta
    if !@type.nil?
      
    elsif !@parser.nil?

    else
      # 错误
      raise "Meta type and parser cannot be nil at the same time"
    end
  end
end