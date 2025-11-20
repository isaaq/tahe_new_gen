# frozen_string_literal: true

require_relative '../../../strategy/base_strategy'

module Plugins; end
module Plugins::Strategy; end
module Plugins::Strategy::Submit; end

module Plugins
  module Strategy
    module Submit
      class VersionComparePublishStrategy < ::Strategy::BaseStrategy
        # 自动注册策略
        strategy_for 'document', 'submit', 'version_compare'
        
        def before_execute(params = {})
          # 验证必要参数
          
          
          raise "缺少必要参数: document_id" unless params[:document_id]
          
          raise "缺少必要参数: compare_version" unless params[:compare_version]
          
          
          
          # 预处理逻辑
          
        end
        
        def perform(params = {})
          # 策略实现
          # 版本比较发布逻辑
          document_id = params[:document_id]
          compare_version = params[:compare_version]
          collection = params[:collection] || 'documents'

          return { success: false, message: "比较版本未指定" } unless compare_version

          # 获取 MongoDB 客户端
          db = Common::M.database
          collection_obj = db[collection]

          # 获取当前文档
          current_doc = collection_obj.find_one({ _id: BSON::ObjectId(document_id) })
          return { success: false, message: "文档不存在" } unless current_doc

          # 获取比较版本
          compare_doc = db['document_versions'].find_one({
            document_id: document_id,
            version: compare_version.to_s
          })

          return { success: false, message: "比较版本不存在" } unless compare_doc

          # 比较版本差异
          differences = []
          current_data = current_doc.reject { |k, v| ['_id', '_created_at', '_updated_at'].include?(k.to_s) }
          compare_data = compare_doc['data'] || {}

          (current_data.keys + compare_data.keys).uniq.each do |key|
            if current_data[key] != compare_data[key]
              differences << { field: key, current: current_data[key], compare: compare_data[key] }
            end
          end

          # 更新文档，记录版本比较结果
          update_result = collection_obj.update_one(
            { _id: BSON::ObjectId(document_id) },
            { '$set' => {
              status: 'submitted',
              submitted_at: Time.now,
              version_compared: true,
              version_comparison: {
                compare_version: compare_version,
                differences: differences,
                compared_at: Time.now
              }
            } }
          )

          { success: true, updated_count: update_result.modified_count, differences: differences, message: "版本比较完成" }
        end
        
        def after_execute(params = {}, result = nil)
          # 后处理逻辑
          
        end
      end
    end
  end
end

