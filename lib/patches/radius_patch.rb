# frozen_string_literal: true

# 修复 Radius::DelegatingOpenStruct 中的 respond_to_missing? 方法
module Radius
  class DelegatingOpenStruct
    # 重写 respond_to_missing? 方法，修复原始实现中的错误
    def respond_to_missing?(method, include_private = false)
      symbol = method.to_s.chomp('=').to_sym
      @hash.key?(symbol) || (@object && @object.respond_to?(method, include_private)) || super
    end
  end
end
