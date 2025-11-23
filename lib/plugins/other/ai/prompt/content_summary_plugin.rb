# frozen_string_literal: true

# AI Prompt 插件：内容摘要插件
# 分类：other/ai_prompt
# 插件ID：ai-prompt-content-summary

module Plugins
  module Other
    module AiPrompt
      class ContentSummaryPlugin
        # 运行：根据输入与Prompt生成输出
        # context:
        # - input: 用户输入
        # - options: Prompt配置
        def run(context = {})
          input = context[:input].to_s
          options = context[:options] || {}

          return { success: true, output: { summary: "", keywords: [] } }

        end
      end
    end
  end
end


