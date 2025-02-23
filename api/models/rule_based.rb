require_relative 'parser'

class RuleBasedParser < ContentParser
  def parse(data)
    validate_content!(data)
    content = data['content']
    
    # 基于规则的解析逻辑
    result = {
      'parsed_by': 'rule_based',
      'content': content,
      'rules_applied': [],
      'confidence': 0.0
    }
    
    # 应用规则集
    apply_rules(content, result)
    
    result
  end
  
  private
  
  def apply_rules(content, result)
    # 示例规则集
    rules = [
      {pattern: /\d{4}-\d{2}-\d{2}/, type: 'date'},
      {pattern: /\d+\.\d+/, type: 'number'},
      {pattern: /[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}/i, type: 'email'}
    ]
    
    rules.each do |rule|
      if content.match?(rule[:pattern])
        result[:rules_applied] << rule[:type]
        result[:confidence] += 0.2
      end
    end
    
    # 限制置信度范围
    result[:confidence] = [1.0, result[:confidence]].min
  end
end
