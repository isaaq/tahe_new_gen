require 'singleton'
require_relative 'prompt_template_service'

class LearningService
  include Singleton

  def initialize
    @prompt_service = PromptTemplateService.instance
  end

  def analyze_feedback(document_id)
    # 获取文档的解析历史和反馈
    history = get_parse_history(document_id)
    feedback = get_feedback_history(document_id)
    
    # 分析反馈并生成优化建议
    analysis = analyze_performance(history, feedback)
    
    # 根据分析结果更新解析策略
    update_parser_strategy(document_id, analysis)
    
    # 记录学习历史
    record_learning(document_id, analysis)
    
    analysis
  end

  def optimize_strategy(parser_type, performance_data)
    strategy_updates = {
      confidence_threshold: calculate_new_threshold(performance_data),
      weight_adjustments: adjust_weights(performance_data),
      template_suggestions: suggest_template_improvements(performance_data)
    }

    # 更新解析器策略
    update_parser_config(parser_type, strategy_updates)
    
    strategy_updates
  end

  private

  def get_parse_history(document_id)
    Common::M[:parse_history].query(
      document_id: document_id
    ).sort(created_at: -1).limit(10).to_a
  end

  def get_feedback_history(document_id)
    Common::M[:parser_feedback].query(
      document_id: document_id
    ).sort(created_at: -1).to_a
  end

  def analyze_performance(history, feedback)
    {
      success_rate: calculate_success_rate(history, feedback),
      common_errors: identify_common_errors(history, feedback),
      performance_trends: analyze_trends(history),
      suggested_improvements: generate_improvements(history, feedback)
    }
  end

  def calculate_success_rate(history, feedback)
    return 0.0 if history.empty?
    
    successful = feedback.count { |f| f[:feedback_type] == 'correct_parse' }
    successful.to_f / history.length
  end

  def identify_common_errors(history, feedback)
    error_feedback = feedback.select { |f| f[:feedback_type] == 'incorrect_parse' }
    error_patterns = error_feedback.group_by { |f| f[:feedback_content] }
    
    error_patterns.transform_values(&:count)
  end

  def analyze_trends(history)
    confidence_trend = history.map { |h| h[:confidence] }
    parse_times = history.map { |h| h[:parse_time] }
    
    {
      avg_confidence: confidence_trend.sum / confidence_trend.length,
      avg_parse_time: parse_times.sum / parse_times.length
    }
  end

  def generate_improvements(history, feedback)
    # 使用LLM生成改进建议
    prompt = @prompt_service.get_template('improve_parser', {
      feedback_history: feedback.to_json,
      current_result: history.first.to_json
    })
    
    response = LLMService.instance.process(prompt)
    JSON.parse(response[:result]) rescue {}
  end

  def update_parser_strategy(document_id, analysis)
    strategy = {
      parser_type: determine_best_parser(analysis),
      confidence_threshold: calculate_threshold(analysis),
      updated_at: Time.now
    }
    
    Common::M[:documents].update(
      document_id: document_id,
      '$set': { '_meta.parser_strategy': strategy }
    )
  end

  def record_learning(document_id, analysis)
    Common::M[:learning_history].add({
      document_id: BSON::ObjectId(document_id),
      analysis: analysis,
      created_at: Time.now
    })
  end

  def determine_best_parser(analysis)
    if analysis[:success_rate] > 0.8
      'rule_based'
    elsif analysis[:common_errors].empty?
      'hybrid'
    else
      'ai'
    end
  end

  def calculate_threshold(analysis)
    base_threshold = 0.7
    adjustment = analysis[:success_rate] - 0.5
    [base_threshold + adjustment, 0.9].min
  end
end
