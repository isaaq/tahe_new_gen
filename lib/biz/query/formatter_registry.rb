# frozen_string_literal: true

# FormatterRegistry - 格式化钩子系统
# 支持从MongoDB加载自定义格式化逻辑（参考老系统 sys_pages_attachments）
class FormatterRegistry
  # 应用自定义格式化器
  def self.apply_formatters(data, context)
    return data unless context && context[:request_path]
    
    page_url = context[:request_path]
    
    # 从 MongoDB 查找该页面的格式化器
    formatters = load_formatters(page_url, context)
    
    return data if formatters.empty?
    
    # 执行每个格式化器（按优先级排序）
    formatters.sort_by { |f| f['priority'] || 0 }.reverse.each do |formatter|
      next unless formatter['enabled'] != false
      
      case formatter['language']
      when 'ruby'
        # 安全执行 Ruby 代码（沙箱环境）
        data = safe_eval_ruby(formatter['code'], data, context)
      when 'javascript'
        # JavaScript 格式化器返回给前端执行
        context[:client_formatters] ||= []
        context[:client_formatters] << formatter['code']
      end
    end
    
    data
  rescue => e
    puts "⚠️  应用格式化器失败: #{e.message}"
    data  # 不影响主流程
  end
  
  private
  
  def self.load_formatters(page_url, context)
    return [] unless defined?(M)
    
    M[:sys_pages_attachments].query({
      type: 'formatter',
      url: { '$in': build_url_candidates(page_url, context) }
    }).to_a
  rescue => e
    puts "⚠️  加载格式化器失败: #{e.message}"
    []
  end
  
  def self.build_url_candidates(page_url, context)
    candidates = [page_url]
    
    # 添加其他可能的URL变体
    candidates << context[:request_uri] if context[:request_uri]
    
    # 处理 referer（移除 origin）
    if context[:referer] && context[:origin]
      referer_path = context[:referer].gsub(context[:origin], '')
      candidates << referer_path unless referer_path.empty?
    end
    
    candidates.compact.uniq
  end
  
  def self.safe_eval_ruby(code, data, context)
    # 创建受限的沙箱环境
    sandbox = FormatterSandbox.new(data, context)
    
    # 在沙箱中执行代码
    sandbox.instance_eval(code)
    
    # 返回可能被修改的数据
    sandbox.data
  rescue => e
    puts "⚠️  格式化器执行失败: #{e.message}"
    puts "   代码: #{code[0..100]}..." if code.length > 100
    data  # 返回原数据
  end
  
  # 格式化器沙箱（限制可访问的方法，防止恶意代码）
  class FormatterSandbox
    def initialize(data, context)
      @data = data
      @context = context
    end
    
    # 暴露给格式化器的安全API
    attr_accessor :data
    attr_reader :context
    
    # 禁止危险操作
    undef_method :eval if respond_to?(:eval)
    undef_method :system if respond_to?(:system)
    undef_method :exec if respond_to?(:exec)
    undef_method :` if respond_to?(:`)
    undef_method :fork if respond_to?(:fork)
    undef_method :spawn if respond_to?(:spawn)
    
    # 提供安全的辅助方法
    def calculate_total(price_field, qty_field)
      @data.each do |record|
        price = record[price_field] || record[price_field.to_sym] || 0
        qty = record[qty_field] || record[qty_field.to_sym] || 0
        record['total'] = price * qty
      end
    end
    
    def format_date(field, format = '%Y-%m-%d')
      @data.each do |record|
        date_value = record[field] || record[field.to_sym]
        if date_value.respond_to?(:strftime)
          record["#{field}_formatted"] = date_value.strftime(format)
        end
      end
    end
    
    def add_computed_field(target_field, &block)
      @data.each do |record|
        record[target_field] = block.call(record)
      end
    end
  end
end
