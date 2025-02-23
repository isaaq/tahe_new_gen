require_relative 'parser'
require_relative '../ai_services/llm_service'
require_relative '../ai_services/prompt_template_service'
require_relative '../ai_services/learning_service'

class AIInterpreter < ContentParser
  def initialize
    @llm_service = LLMService.instance
    @prompt_service = PromptTemplateService.instance
    @learning_service = LearningService.instance
  end
  
  def parse(data)
    validate_content!(data)
    content = data['content']
    
    # 获取解析历史和上下文
    context = build_context(data)
    
    # 构建动态提示词
    prompt = build_dynamic_prompt(content, context)
    
    # 调用LLM服务
    start_time = Time.now
    response = @llm_service.process(prompt)
    parse_time = Time.now - start_time
    
    if response[:status] == 'success'
      result = {
        'parsed_by': 'ai',
        'content': content,
        'interpretation': response[:result],
        'confidence': calculate_confidence(response[:result]),
        'parse_time': parse_time,
        'context_used': context
      }
      
      # 记录解析历史
      record_parse_history(data, result)
      
      # 追踪模板性能
      track_template_performance(result)
      
      result
    else
      raise "AI interpretation failed: #{response[:error]}"
    end
  end
  
  private
  
  def build_context(data)
    doc_id = data['_id']
    return {} unless doc_id
    
    # 获取最近的解析历史
    history = Common::M[:parse_history].query(
      document_id: doc_id
    ).sort(created_at: -1).limit(5).to_a
    
    # 获取相关的反馈
    feedback = Common::M[:parser_feedback].query(
      document_id: doc_id
    ).sort(created_at: -1).limit(5).to_a
    
    {
      history_performance: summarize_history(history),
      recent_feedback: summarize_feedback(feedback),
      document_meta: data['_meta']
    }
  end
  
  def build_dynamic_prompt(content, context)
    @prompt_service.get_template('parse_content', {
      content: content,
      history_performance: context[:history_performance].to_json,
      context: context.to_json
    })
  end
  
  def calculate_confidence(result)
    begin
      parsed = JSON.parse(result)
      # 基于结果完整性和质量计算置信度
      completeness = assess_completeness(parsed)
      quality = assess_quality(parsed)
      
      confidence = (completeness * 0.6 + quality * 0.4).round(2)
      [confidence, 1.0].min
    rescue JSON::ParserError
      0.3 # 如果返回结果不是有效的JSON，给出较低的置信度
    end
  end
  
  def assess_completeness(parsed)
    required_fields = ['main_topic', 'key_points', 'entities', 'sentiment']
    present_fields = required_fields.count { |f| parsed[f] && !parsed[f].empty? }
    present_fields.to_f / required_fields.length
  end
  
  def assess_quality(parsed)
    # 评估结果质量的启发式规则
    quality_score = 0.0
    
    # 检查主题提取质量
    quality_score += 0.3 if parsed['main_topic'].to_s.length > 10
    
    # 检查关键点数量和质量
    if parsed['key_points'].is_a?(Array)
      points_score = parsed['key_points'].count { |p| p.to_s.length > 15 } * 0.1
      quality_score += [points_score, 0.3].min
    end
    
    # 检查实体识别
    if parsed['entities'].is_a?(Array)
      quality_score += 0.2 if parsed['entities'].length > 2
    end
    
    # 检查情感分析
    quality_score += 0.2 if ['positive', 'neutral', 'negative'].include?(parsed['sentiment'])
    
    quality_score
  end
  
  def record_parse_history(data, result)
    history = {
      document_id: data['_id'],
      parser_type: 'ai',
      input: data['content'],
      output: result,
      parse_time: result['parse_time'],
      confidence: result['confidence'],
      created_at: Time.now
    }
    
    Common::M[:parse_history].add(history)
  end
  
  def track_template_performance(result)
    @prompt_service.track_template_performance(
      'parse_content',
      {
        success: true,
        confidence: result['confidence']
      }
    )
  end
  
  def summarize_history(history)
    return 'No previous parsing history' if history.empty?
    
    avg_confidence = history.map { |h| h['confidence'] }.sum / history.length
    "Average confidence: #{avg_confidence.round(2)}, Total attempts: #{history.length}"
  end
  
  def summarize_feedback(feedback)
    return 'No feedback available' if feedback.empty?
    
    feedback_types = feedback.group_by { |f| f['feedback_type'] }
    feedback_types.transform_values(&:count).to_json
  end
end
