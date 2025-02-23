class ContentParser
  def self.select_parser(parser_name)
    case parser_name
    when 'rule_based'
      RuleBasedParser.new
    when 'ai'
      AIInterpreter.new
    when 'hybrid'
      HybridParser.new
    else
      raise "Unknown parser type: #{parser_name}"
    end
  end

  def parse(data)
    raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
  end

  protected

  def validate_content!(data)
    raise ArgumentError, "Content cannot be empty" if data['content'].nil? || data['content'].empty?
  end
end
