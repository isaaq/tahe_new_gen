# frozen_string_literal: true

module FieldBehavior
  def self.included(base)
    base.class_eval do
      attr_accessor :sort_num, :name, :display_name, :description, :type,
                  :is_system, :is_required, :is_searchable, :is_sortable,
                  :form_additional_attr, :form_css, :length_range, :regex,
                  :regex_error_msg, :is_unique, :is_common_info,
                  :is_global_search, :is_with_omni, :deny_group_list,
                  :deny_role_list, :value
    end
  end

  def check
    c_list = methods.select { |s| s.start_with?('c_') }
    flag = true
    c_list.each do |c|
      c_r = send(c)
      flag &&= c_r
    end
    flag
  end
  
  # 验证字段是否有效
  def valid?
    # 默认实现，子类可以重写该方法
    if respond_to?(:check)
      return check
    end
    
    # 如果没有 check 方法，则检查是否有任何以 c_ 开头的方法
    c_methods = methods.select { |m| m.to_s.start_with?('c_') }
    
    if c_methods.empty?
      # 如果没有验证方法，则默认为有效
      return true
    else
      # 执行所有验证方法
      c_methods.all? { |m| send(m) }
    end
  end

  def c_required
    return false if value.nil?
    return true unless @is_required
    value.length.positive?
  end

  def c_length_range
    return false if value.nil?
    return true if @length_range.nil?
    value.length <= @length_range.max && value >= @length_range.min
  end

  def c_is_unique
    return false if value.nil?
    return true if length_range.nil?
    # TODO: 实现唯一性检查
    true
  end

  def c_regex
    return false if value.nil? || @regex.nil?
    value.match?(@regex)
  end
end
