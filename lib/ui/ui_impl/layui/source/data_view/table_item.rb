# frozen_string_literal: true

require_relative '../../layui_element'

# TableItem - 数据表格项
# 使用配置注册系统将kr:datatable转换为l:table
class TableItem < LayuiElement
  attr_accessor :elem, :url, :cols, :data, :id, :toolbar, :defaultToolbar, :width, :height, :maxHeight, :cellMinWidth,
                :cellMaxWidth, :lineStyle, :className, :css, :cellExpandedMode, :cellExpandedWidth, :escape, :totalRow, :page,
                :fk_hints,           # 新增：收集的FK配置
                :column_templates    # 新增：收集的模板脚本

  def pre_process
    # 提取kr配置
    @kr_attrs = extract_kr_attributes
    
    # 解析子列，收集FK配置和模板
    @fk_hints = []
    @column_templates = []
    
    collect_column_metadata
  end

  def elename
    'datatable'
  end

  def output_tag
    # 构建上下文
    context = build_context
    
    # 使用配置注册表转换（关键！）
    l_attrs = ComponentConfigRegistry.transform('datatable', @kr_attrs, context)
    
    # 收集列元数据（包含FK配置）
    collect_column_metadata
    
    
    # 添加FK提示到查询协议
    if @fk_hints.any?
      l_attrs[:query_protocol] = build_query_protocol
    end
    
    # 生成l:table标签
    attrs_str = serialize_attrs(l_attrs)
    
    # 拼接模板脚本
    templates_html = @column_templates.compact.join("\n")
    
    # 生成正确的LayUI表格结构
    table_id = @kr_attrs['id'] || 'table_default'
    
    # 构建查询协议（包含FK关联）
    query_protocol = build_query_protocol
    query_protocol_json = query_protocol.to_json
    
    # 动态生成列配置（替代硬编码）
    cols_json = generate_cols_json
    
    <<~HTML
      <table id="#{table_id}" lay-filter="#{table_id}"></table>
      
      #{templates_html}
      
      <script>
        layui.use(['table'], function() {
          var table = layui.table;
          
          // 查询协议
          var queryProtocol = #{query_protocol_json};
          
          // 渲染表格
          table.render({
            elem: '##{table_id}',
            url: '/api/query',
            method: 'POST',
            contentType: 'application/json',
            request: {
              pageName: 'page',
              limitName: 'limit'
            },
            parseData: function(res) {
              return {
                code: res.code,
                msg: res.msg,
                count: res.count || res.data.length,
                data: res.data
              };
            },
            where: queryProtocol,
            page: true,
            limit: #{@kr_attrs['limit'] || 20},
            cols: #{cols_json},
            done: function(res, curr, count) {
              console.log('表格加载完成:', res);
            }
          });
        });
      </script>
    HTML
  end

  private
  
  def generate_cols_json
    # 从子元素动态生成列配置
    cols = []
    
    return '[[]]' unless @children
    
    # 如果children是字符串，需要解析kr:col标签
    if @children.is_a?(String)
      cols = parse_cols_from_string(@children)
    else
      # 确保children是数组
      children_array = @children.is_a?(Array) ? @children : [@children]
      
      children_array.each do |child|
        next unless child.is_a?(TableColItem)
        
        col_def = {
          field: child.field,
          title: child.title,
          key: child.field # 添加 key 属性，LayUI 需要
        }
        
        # 添加可选属性
        col_def[:width] = child.width.to_i if child.width
        col_def[:sort] = true if child.sort == 'true' || child.sort == true
        col_def[:fixed] = child.fixed if child.fixed
        col_def[:hide] = true if child.hide == 'true' || child.hide == true
        col_def[:minWidth] = child.minWidth.to_i if child.minWidth
        
        # 如果有FK配置，使用result_field
        if child.get_fk_config
          col_def[:field] = child.get_fk_config[:result_field]
          col_def[:key] = child.get_fk_config[:result_field] # 更新 key 为 result_field
        end
        
        # 如果有templet模板
        if child.templet
          col_def[:templet] = "##{child.templet}"
        end
        
        cols << col_def
      end
    end
    
    # 返回JSON格式
    "[#{cols.map(&:to_json).join(',')}]"
  end
  
  def parse_cols_from_string(children_string)
    cols = []
    
    # 解析字符串内容，查找kr:col标签
    matches = children_string.scan(/<kr:col\s+([^>]*?)\s*\/>/i)
    
    matches.each do |match|
      # match 是一个数组，第一个元素是捕获的属性字符串
      attrs_string = match.is_a?(Array) ? match[0] : match
      attrs = parse_attributes_from_string(attrs_string)
      
      col_def = {
        field: attrs['field'],
        title: attrs['title'],
        key: attrs['field'] # 添加 key 属性，LayUI 需要
      }
      
      # 添加可选属性
      col_def[:width] = attrs['width'].to_i if attrs['width']
      col_def[:sort] = true if attrs['sort'] == 'true'
      col_def[:fixed] = attrs['fixed'] if attrs['fixed']
      col_def[:hide] = true if attrs['hide'] == 'true'
      col_def[:minWidth] = attrs['minWidth'].to_i if attrs['minWidth']
      
      # 处理FK关联
      if attrs['relation']
        relation = attrs['relation']
        relation_field = attrs['relation_field'] || 'name'
        relation_key = attrs['relation_key'] || attrs['field']
        
        # 构建FK配置
        fk_config = build_fk_config_from_attrs(attrs)
        if fk_config
          col_def[:field] = fk_config[:result_field]
          col_def[:key] = fk_config[:result_field] # 更新 key 为 result_field
          @fk_hints << fk_config
        end
      end
      
      # 处理枚举
      if attrs['enum'] || attrs['type'] == 'enum'
        enum_values = parse_enum_values(attrs['enum'])
        if enum_values
          template_id = "enum_#{attrs['field']}_#{SecureRandom.hex(3)}"
          col_def[:templet] = "##{template_id}"
          @column_templates << generate_enum_template(template_id, attrs['field'], enum_values)
        end
      end
      
      cols << col_def
    end
    
    cols
  end
  
  def parse_attributes_from_string(attrs_string)
    attrs = {}
    attrs_string.scan(/(\w+)="([^"]*)"/) do |key, value|
      attrs[key] = value
    end
    attrs
  end
  
  def build_fk_config_from_attrs(attrs)
    relation = attrs['relation']
    relation_field = attrs['relation_field'] || 'name'
    relation_key = attrs['relation_key'] || attrs['field']
    
    # 使用 RelationRegistry 动态解析集合名称（替代硬编码）
    if defined?(RelationRegistry)
      relation_config = RelationRegistry.resolve(
        relation,
        relation_key,
        extract_collection_name,
        nil
      )
      target_collection = relation_config[:collection]
    else
      # 降级：简单推断
      target_collection = "org_#{relation}s"
    end
    
    {
      relation_name: relation,
      collection: target_collection,
      foreign_key: relation_key,
      display_field: relation_field,
      result_field: "#{relation}_#{relation_field}"
    }
  end
  
  def parse_enum_values(enum_string)
    return nil unless enum_string
    
    # "男,女,未知" -> [{value: 0, label: "男"}, {value: 1, label: "女"}, {value: 2, label: "未知"}]
    enum_string.split(',').map.with_index do |label, idx|
      { value: idx, label: label.strip }
    end
  end
  
  def generate_enum_template(template_id, field, enum_values)
    enum_map = enum_values.map { |e| "#{e[:value]}: '#{e[:label]}'" }.join(', ')
    
    <<~HTML
      <script type="text/html" id="#{template_id}">
        {{# 
          var enumMap = { #{enum_map} };
          var label = enumMap[d.#{field}] || '未知';
          var colorMap = ['orange', 'green', 'blue', 'red', 'gray', 'cyan', 'purple'];
          var color = colorMap[d.#{field}] || 'gray';
        }}
        <span class="layui-badge layui-bg-{{color}}">{{label}}</span>
      </script>
    HTML
  end

  def collect_column_metadata
    # 遍历子元素，收集TableColItem的FK配置和模板
    return unless @children
    
    # 如果children是字符串，需要解析它
    if @children.is_a?(String)
      # 解析字符串内容，查找kr:col标签
      parse_cols_from_string(@children)
    else
      # 确保children是数组
      children_array = @children.is_a?(Array) ? @children : [@children]
      
      children_array.each do |child|
        next unless child.respond_to?(:pre_process)
        
        # 触发子元素的pre_process
        child.pre_process
        
        # 如果是TableColItem，收集其FK配置和模板
        if child.is_a?(TableColItem)
          fk_config = child.get_fk_config
          @fk_hints << fk_config if fk_config
          
          # 收集FK模板
          fk_template = child.generate_fk_template
          @column_templates << fk_template if fk_template
          
          # 收集枚举模板
          enum_template = child.generate_enum_template
          @column_templates << enum_template if enum_template
        end
      end
    end
  end
  
  def parse_children_from_string(children_string)
    # 解析字符串内容，查找l:t-col标签（第一次编译后的结果）
    # 使用正则表达式匹配l:t-col标签
    matches = children_string.scan(/<l:t-col[^>]*>/i)
    
    matches.each do |match|
      # 提取属性
      attrs = extract_attributes_from_tag(match)
      
      # 检查是否有templet属性（FK关联的标识）
      if attrs['templet'] && attrs['templet'].include?('fk_')
        # 从templet中提取FK信息
        fk_config = build_fk_config_from_templet(attrs)
        if fk_config && !@fk_hints.any? { |existing| existing[:relation_name] == fk_config[:relation_name] }
          @fk_hints << fk_config
        end
      end
    end
  end
  
  def extract_attributes_from_tag(tag_string)
    attrs = {}
    tag_string.scan(/(\w+)="([^"]*)"/) do |key, value|
      attrs[key] = value
    end
    attrs
  end
  
  def build_fk_config_from_attrs(attrs)
    relation = attrs['relation']
    relation_field = attrs['relation_field']
    relation_key = attrs['relation_key'] || attrs['field']
    
    # 使用 RelationRegistry 动态解析集合名称（替代硬编码）
    if defined?(RelationRegistry)
      relation_config = RelationRegistry.resolve(
        relation,
        relation_key,
        extract_collection_name,
        nil
      )
      target_collection = relation_config[:collection]
    else
      # 降级：简单推断
      target_collection = "b_#{relation}s"
    end
    
    {
      relation_name: relation,
      collection: target_collection,
      foreign_key: relation_key,
      display_field: relation_field,
      result_field: "#{relation}_#{relation_field}"
    }
  end
  
  def build_fk_config_from_templet(attrs)
    templet = attrs['templet']
    field = attrs['field']
    
    # 从templet中提取FK信息
    # templet格式: #fk_org_id_aee20e
    if templet =~ /#fk_(\w+)_/
      relation_key = $1
      
      # 推断relation和display_field（智能推断，无硬编码）
      if field.end_with?('_name')
        relation = field.gsub(/_name$/, '')
        display_field = 'name'
      else
        relation = relation_key.gsub(/_id$/, '')
        display_field = 'name'
      end
      
      # 使用 RelationRegistry 动态解析集合名称（替代硬编码）
      if defined?(RelationRegistry)
        relation_config = RelationRegistry.resolve(
          relation,
          relation_key,
          extract_collection_name,
          nil
        )
        target_collection = relation_config[:collection]
      else
        # 降级：简单推断
        target_collection = "b_#{relation}s"
      end
      
      {
        relation_name: relation,
        collection: target_collection,
        foreign_key: relation_key,
        display_field: display_field,
        result_field: field
      }
    end
  end
  
  def build_query_protocol
    {
      collection: @kr_attrs['source'] || extract_collection_name,
      filter: {},
      expand: @fk_hints.map do |fk|
        {
          relation: fk[:relation_name],
          collection: fk[:collection],
          foreign_key: fk[:foreign_key],
          display_field: fk[:display_field],
          result_field: fk[:result_field]
        }
      end,
      sort: {},
      page: 1,
      limit: @kr_attrs['limit']&.to_i || 20
    }
  end
  
  def extract_collection_name
    # 从source属性提取集合名
    @kr_attrs['source'] || 'unknown'
  end
  
  def extract_kr_attributes
    kr_attrs = {}
    
    # 从tag属性中提取配置
    tag.attr.each do |key, value|
      kr_attrs[key] = value
    end
    
    kr_attrs
  end
  
  def build_context
    {
      scenario: 'single_table',
      parent_component: self,
      linkage: false,
      fk_configs: @fk_hints
    }
  end
  
  def serialize_attrs(attrs)
    attrs.map do |key, value|
      case value
      when Hash
        "#{key}='#{value.to_json}'"
      when Array
        "#{key}='#{value.to_json}'"
      when String
        "#{key}='#{value}'"
      when true
        "#{key}='true'"
      when false
        "#{key}='false'"
      else
        "#{key}=#{value}"
      end
    end.join(' ')
  end
end
