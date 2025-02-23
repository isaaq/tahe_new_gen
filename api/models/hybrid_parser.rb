require_relative 'parser'
require_relative 'rule_based'
require_relative 'ai_interpreter'
require 'json'
require 'logger'

class HybridParser < ContentParser
  def initialize
    @rule_parser = RuleBasedParser.new
    @ai_parser = AIInterpreter.new
    @logger = Logger.new(STDOUT)
  end
  
  def parse(data)
    validate_content!(data)
    content = data['content']
    
    begin
      # 判断是否为JSON/结构化数据
      if structured_data?(content)
        @logger.info "检测到结构化数据，使用规则解析器"
        return @rule_parser.parse(data)
      end
      
      # 对于非结构化数据，使用混合解析
      @logger.info "检测到非结构化数据，使用混合解析"
      
      # 先用规则解析器预处理
      rule_result = @rule_parser.parse(data)
      
      # 再用AI解析器深度解析
      ai_result = @ai_parser.parse(data)
      
      # 合并结果
      merge_results(rule_result, ai_result)
    rescue => e
      @logger.error "解析过程发生错误: #{e.message}"
      @logger.error e.backtrace.join("\n")
      
      {
        'status': 'error',
        'message': '解析失败，请检查输入格式',
        'error_details': e.message,
        'content': content
      }
    end
  end
  
  private
  
  def structured_data?(content)
    # 尝试解析JSON
    JSON.parse(content)
    true
  rescue JSON::ParserError
    # 检查其他结构化数据特征
    # 例如: XML, YAML, CSV等格式
    content.strip.start_with?('<') || # 可能是XML
    content.include?(',') || # 可能是CSV
    content.include?(':') # 可能是YAML
  end
  
  def merge_results(rule_result, ai_result)
    {
      'parsed_by': 'hybrid',
      'content': rule_result[:content],
      'rule_based_result': rule_result,
      'ai_result': ai_result,
      'confidence': calculate_hybrid_confidence(rule_result, ai_result)
    }
  end
  
  def calculate_hybrid_confidence(rule_result, ai_result)
    rule_weight = 0.4
    ai_weight = 0.6
    
    rule_confidence = rule_result[:confidence] || 0
    ai_confidence = ai_result['confidence'] || 0
    
    (rule_confidence * rule_weight + ai_confidence * ai_weight).round(2)
  end
end
