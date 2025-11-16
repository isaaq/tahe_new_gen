# frozen_string_literal: true

require 'securerandom'

class TableColItem < LayuiElement
  attr_accessor :type, :fixed, :field, :width, :title, :sort, :totalRow, :fieldTitle, :hide, :expandedMode, :edit,
                :minWidth, :expandedWidth, :templet,
                # 新增：kr层传递的元数据
                :relation,           # 关联名称（语义化）
                :relation_field,     # 要显示的关联字段
                :relation_key,       # 外键字段名
                :relation_collection, # 显式指定的目标集合（可选）
                :enum_values,        # 枚举值列表
                :fk_config          # 内部使用：完整FK配置

  def elename
    't-col'
  end
  
  def pre_process
    # 从kr层属性转换为内部FK配置
    if tag.attr['relation']
      @relation = tag.attr['relation']
      @relation_field = tag.attr['relation_field']
      @relation_key = tag.attr['relation_key'] || tag.attr['field']
      @relation_collection = tag.attr['relation_collection']  # 可选的显式配置
      
      # 构建内部FK配置（用于后端查询）
      @fk_config = build_fk_config_from_relation
      
      # 生成templet ID
      @templet ||= "fk_#{(@field || @relation_key).to_s.gsub(/[^a-zA-Z0-9]/, '_')}_#{SecureRandom.hex(3)}"
    end
    
    # 处理枚举（支持显式指定或从模型自动读取）
    if tag.attr['enum']
      # 优先使用显式指定的枚举值
      @enum_values = parse_enum(tag.attr['enum'])
      @templet ||= "enum_#{(@field || 'field').to_s.gsub(/[^a-zA-Z0-9]/, '_')}_#{SecureRandom.hex(3)}"
    elsif tag.attr['type'] == 'enum' && @field
      # 尝试从模型自动读取枚举值（避免硬编码）
      @enum_values = get_enum_from_model
      @templet ||= "enum_#{@field.to_s.gsub(/[^a-zA-Z0-9]/, '_')}_#{SecureRandom.hex(3)}" if @enum_values
    end
  end

  def props
    vals = {
      type: @type,
      fixed: @fixed,
      field: @fk_config ? @fk_config[:result_field] : @field,
      width: @width,
      title: @title,
      sort: @sort,
      totalRow: @totalRow,
      fieldTitle: @fieldTitle,
      hide: @hide,
      expandedMode: @expandedMode,
      edit: @edit,
      minWidth: @minWidth,
      expandedWidth: @expandedWidth,
      templet: @templet ? "##{@templet}" : nil
    }
    vals.compact.map { |key, value| "#{key}=\"#{value}\"" }.join(' ')
  end

  def output_tag
    "<#{prefix}:#{elename} #{props} />"
  end
  
  # 返回FK配置（供TableItem收集）
  def get_fk_config
    @fk_config
  end
  
  # 生成FK模板脚本
  def generate_fk_template
    return nil unless @fk_config
    
    template_id = @templet
    result_field = @fk_config[:result_field]
    
    <<~HTML
      <script type="text/html" id="#{template_id}">
        {{# if (d.#{result_field}) { }}
          {{ d.#{result_field} }}
        {{# } else { }}
          <span style="color: #ccc;">-</span>
        {{# } }}
      </script>
    HTML
  end
  
  # 生成枚举模板脚本
  def generate_enum_template
    return nil unless @enum_values
    
    template_id = @templet
    enum_map = @enum_values.map { |e| "#{e[:value]}: '#{e[:label]}'" }.join(', ')
    
    # 使用%Q来避免模板语法冲突
    %Q{
      <script type="text/html" id="#{template_id}">
        {{# 
          var enumMap = { #{enum_map} };
          var label = enumMap[d.#{@field}] || '未知';
          var colorMap = ['orange', 'green', 'blue', 'red', 'gray', 'cyan', 'purple'];
          var color = colorMap[d.#{@field}] || 'gray';
        }}
        <span class="layui-badge layui-bg-{{color}}">{{label}}</span>
      </script>
    }
  end
  
  private
  
  def build_fk_config_from_relation
    # 如果用户显式指定了集合名，使用显式配置
    explicit_config = @relation_collection ? { collection: @relation_collection } : nil
    
    # 调用 RelationRegistry 解析（如果已加载）
    if defined?(RelationRegistry)
      relation_config = RelationRegistry.resolve(
        @relation,
        @relation_key,
        extract_parent_collection,
        explicit_config
      )
      
      target_collection = relation_config[:collection]
    else
      # 降级：使用简单推断
      target_collection = @relation_collection || "b_#{@relation}s"
    end
    
    {
      relation_name: @relation,
      collection: target_collection,
      foreign_key: @relation_key,
      display_field: @relation_field,
      result_field: "#{@relation}_#{@relation_field}"
    }
  end
  
  def extract_parent_collection
    # 尝试从父级TableItem获取集合名
    parent = tag.parent
    while parent
      if parent.attr['source']
        return parent.attr['source']
      end
      parent = parent.parent
    end
    nil
  end
  
  def parse_enum(enum_string)
    # "待支付,已支付,已完成" -> [{value: 0, label: "待支付"}, ...]
    enum_string.split(',').map.with_index do |label, idx|
      { value: idx, label: label.strip }
    end
  end
  
  def get_enum_from_model
    # 从模型定义读取枚举值（替代硬编码）
    return nil unless defined?(ModelMetadataHelper)
    
    parent_collection = extract_parent_collection
    return nil unless parent_collection && @field
    
    enum_values = ModelMetadataHelper.get_enum_values(parent_collection, @field)
    
    if enum_values
      puts "📚 从模型读取枚举: #{parent_collection}.#{@field} -> #{enum_values.map { |e| e[:label] }.join(',')}" if defined?(dev?) && dev?
    end
    
    enum_values
  end
end
