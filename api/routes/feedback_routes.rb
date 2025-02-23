require 'sinatra/base'

module FeedbackRoutes
  def self.registered(app)
    app.post '/feedback' do
      content_type :json
      payload = JSON.parse(request.body.read)
      
      begin
        # 验证必要字段
        required = ['document_id', 'feedback_type', 'feedback_content']
        missing = required - payload.keys
        halt 400, {error: "Missing fields: #{missing.join(', ')}"}.to_json unless missing.empty?
        
        # 创建反馈记录
        feedback = {
          document_id: BSON::ObjectId(payload['document_id']),
          feedback_type: payload['feedback_type'],
          feedback_content: payload['feedback_content'],
          created_at: Time.now
        }
        
        # 存储反馈
        result = Common::M.insert_one('parser_feedback', feedback)
        
        # 更新文档的解析器选择策略
        update_parser_strategy(payload['document_id'], payload['feedback_type'])
        
        {success: true, feedback_id: result.inserted_id.to_s}.to_json
      rescue => e
        status 500
        {error: e.message}.to_json
      end
    end
  end
  
  private
  
  def self.update_parser_strategy(doc_id, feedback_type)
    # 基于反馈更新文档的解析器选择策略
    strategy_updates = {
      'incorrect_parse': 'ai',      # 如果规则解析错误，切换到AI解析
      'partial_parse': 'hybrid',    # 如果解析不完整，使用混合解析
      'correct_parse': nil          # 保持当前解析器
    }
    
    new_parser = strategy_updates[feedback_type.to_sym]
    return unless new_parser
    
    Common::M.update(
      'documents',
      {_id: BSON::ObjectId(doc_id)},
      {'$set': {'_meta.parser': new_parser}}
    )
  end
end
