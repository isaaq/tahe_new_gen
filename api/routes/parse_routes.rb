require 'sinatra/base'
require_relative '../models/parser'

module ParseRoutes
  def self.registered(app)
    app.get '/parse/:id' do
      content_type :json
      
      begin
        # 从MongoDB获取文档
        doc = Common::M[:documents].query(_id: BSON::ObjectId(params[:id])).to_a[0]
        raise "Document not found" unless doc
        
        # 获取解析器类型
        parser_type = doc['_meta']&.dig('parser') || 'hybrid'
        
        # 选择合适的解析器
        parser = ContentParser.select_parser(doc['parser_type'] || 'rule_based')
        result = parser.parse(doc)
        
        # 存储解析结果
        doc['_meta'] ||= {}
        doc['_meta']['parsed'] = true
        doc['_meta']['parsed_at'] = Time.now
        doc['parsed_content'] = result
        
        Common::M[:documents].update({_id: doc['_id']}, {'$set': doc})
        
        result.to_json
      rescue => e
        status 500
        {error: e.message}.to_json
      end
    end
  end
end
