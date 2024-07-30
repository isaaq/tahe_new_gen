class Field
  attr_accessor :sort_num, :name, :display_name, :description, :type, :is_system, :is_required, :is_searchable, :is_sortable, :form_additional_attr, :form_css, :length_range, :regex, :regex_error_msg, :is_unique, :is_common_info, :is_global_search, :is_with_omni, :deny_group_list, :deny_role_list, :value

  def check
    c_list = self.methods.select {|s| s.start_with?('c_')}
    flag = true
    c_list.each do |c|
      c_r = send(c)
      flag &&= c_r
    end
  end

  def c_required
    return false if value.nil?
    return true if !@is_required
    value.length > 0
  end

  def c_length_range
    return false if value.nil?
    return true if @length_range
    value.length <= @length_range.max && value >= @length_range.min
  end

  def c_is_unique
    return false if value.nil?
    return true if length_range.nil?
    # TODO
  end

  def c_regex

  end
end