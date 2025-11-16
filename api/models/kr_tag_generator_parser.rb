# frozen_string_literal: true

require_relative 'parser'
require_relative '../ai_services/llm_service'
require_relative '../ai_services/prompt_template_service'
require_relative '../../lib/ui/config/model_metadata_helper'

class KrTagGeneratorParser < ContentParser
  def initialize
    @llm_service = LLMService.instance
    @prompt_service = PromptTemplateService.instance
  end
  
  def parse(data)
    validate_content!(data)
    content = data['content']
    
    # 获取数据库上下文
    context = build_kr_context(data)
    
    # 生成kr标签
    generated_tags = generate_kr_tags(content, context)
    
    # 验证kr标签格式
    validate_kr_tags!(generated_tags)
    
    # 构建记录
    tag_record = build_tag_record(generated_tags, content, data)
    
    {
      'parsed_by': 'kr_tag_generator',
      'content': content,
      'kr_tags': generated_tags,
      'tag_record': tag_record,
      'context_used': context
    }
  end
  
  private
  
  def build_kr_context(data)
    # 获取所有可用的集合和模型信息
    collections = get_available_collections
    models_info = collections.map do |collection|
      {
        collection: collection,
        fields: get_collection_fields(collection),
        relations: get_collection_relations(collection)
      }
    end
    
    {
      available_collections: collections,
      models_info: models_info,
      kr_tag_spec: get_kr_tag_specification
    }
  end
  
  def generate_kr_tags(content, context)
    prompt = @prompt_service.get_template('generate_kr_tags', {
      content: content,
      context: context.to_json
    })
    
    response = @llm_service.process(prompt)
    
    if response && response[:status] == 'success' && response[:result]
      kr_tags = response[:result]
      
      # 提取ERB代码块
      if kr_tags =~ /```erb\n(.*?)\n```/m
        kr_tags = $1
      elsif kr_tags =~ /```\n(.*?)\n```/m
        kr_tags = $1
      end
      
      kr_tags.strip
    else
      raise "Kr tag generation failed: #{response.inspect}"
    end
  end
  
  def validate_kr_tags!(kr_tags)
    # 基本验证：必须包含kr标签
    unless kr_tags =~ /<kr:\w+/
      raise "生成的代码不包含有效的kr标签"
    end
    
    # 验证标签闭合（简单验证）
    open_tags = kr_tags.scan(/<kr:(\w+)/).flatten
    close_tags = kr_tags.scan(/<\/kr:(\w+)/).flatten
    
    # 简单验证（不完全准确，但能发现明显错误）
    if open_tags.size < close_tags.size
      raise "kr标签闭合不匹配：关闭标签过多"
    end
  end
  
  def build_tag_record(kr_tags, original_content, data)
    {
      name: generate_tag_name(original_content),
      content: kr_tags,
      original_requirement: original_content,
      file_path: generate_file_path(original_content),
      created_at: Time.now,
      updated_at: Time.now,
      status: 'generated',
      type: 'kr_tags'
    }
  end
  
  def get_available_collections
    ObjectSpace.each_object(Class)
      .select { |c| c.respond_to?(:表名) }
      .map { |c| c.表名 }
      .compact
      .uniq
  rescue
    []
  end
  
  def get_collection_fields(collection)
    ModelMetadataHelper.get_all_fields(collection) rescue []
  end
  
  def get_collection_relations(collection)
    fields = get_collection_fields(collection)
    relations = []
    
    fields.each do |field|
      if field[:type] == 'Link' || field[:is_foreign_key]
        link_info = ModelMetadataHelper.get_link_info(collection, field[:name])
        if link_info
          relations << {
            field: field[:name],
            relation: extract_relation_name(field[:name]),
            target_collection: link_info[:link_to_collection]
          }
        end
      end
    end
    
    relations
  end
  
  def extract_relation_name(fk_name)
    fk_name.to_s.sub(/_id(s)?$/, '')
  end
  
  def get_kr_tag_specification
    # 返回kr标签规范
    {
      datatable: {
        attributes: ['source', 'page', 'checkbox', 'fields'],
        children: ['col']
      },
      col: {
        attributes: ['title', 'field', 'width', 'relation', 'relation_field', 'enum'],
        self_closing: true
      },
      form: {
        attributes: ['model', 'action', 'method'],
        children: ['input', 'select', 'textarea']
      },
      tree_table_layout: {
        attributes: ['tree_source', 'table_source', 'link_param'],
        self_closing: true
      }
    }
  end
  
  def generate_tag_name(content)
    # 从内容提取名称
    words = content.gsub(/[^\p{Han}\w\s]/, '').split.first(3)
    "generated_#{words.join('_')}_#{Time.now.to_i}"
  end
  
  def generate_file_path(content)
    # 生成文件路径
    words = content.gsub(/[^\p{Han}\w\s]/, '').split.first(2)
    file_name = words.join('_') || 'generated'
    "api/views/#{file_name}_page.erb"
  end
end


