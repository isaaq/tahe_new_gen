# frozen_string_literal: true

require_relative 'parser'
require_relative '../ai_services/llm_service'
require_relative '../ai_services/prompt_template_service'
require_relative '../../lib/ui/config/model_metadata_helper'
require 'yaml'

class SchemaGeneratorParser < ContentParser
  def initialize
    @llm_service = LLMService.instance
    @prompt_service = PromptTemplateService.instance
  end
  
  def parse(data)
    validate_content!(data)
    content = data['content']
    
    # 获取数据库上下文
    context = build_schema_context(data)
    
    # 生成schema
    generated_schema = generate_schema(content, context)
    
    # 验证schema格式
    validate_schema!(generated_schema)
    
    # 构建schema记录
    schema_record = build_schema_record(generated_schema, content, data)
    
    {
      'parsed_by': 'schema_generator',
      'content': content,
      'schema': generated_schema,
      'schema_record': schema_record,
      'context_used': context
    }
  end
  
  private
  
  def build_schema_context(data)
    # 获取所有可用的模型和集合
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
      models_info: models_info
    }
  end
  
  def generate_schema(content, context)
    prompt = @prompt_service.get_template('generate_crud_schema', {
      content: content,
      context: context.to_json
    })
    
    response = @llm_service.process(prompt)
    
    if response && response[:status] == 'success' && response[:result]
      schema_text = response[:result]
      
      # 提取YAML部分
      if schema_text =~ /```yaml\n(.*?)\n```/m
        schema_text = $1
      elsif schema_text =~ /```\n(.*?)\n```/m
        schema_text = $1
      end
      
      # 解析YAML
      YAML.load(schema_text)
    else
      raise "Schema generation failed: #{response.inspect}"
    end
  end
  
  def validate_schema!(schema)
    raise "Schema must have 'type' field" unless schema['type']
    raise "Schema must have 'data' field" unless schema['data']
    raise "Schema type must be 'datamanage' or 'crud'" unless ['datamanage', 'crud'].include?(schema['type'])
  end
  
  def build_schema_record(schema, original_content, data)
    {
      name: generate_schema_name(schema, original_content),
      type: schema['type'],
      content: schema,
      original_requirement: original_content,
      file_path: generate_file_path(schema),
      created_at: Time.now,
      updated_at: Time.now,
      status: 'generated'
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
            target_collection: link_info[:link_to_collection],
            type: 'belongs_to'
          }
        end
      end
    end
    
    relations
  end
  
  def extract_relation_name(fk_name)
    fk_name.to_s.sub(/_id(s)?$/, '')
  end
  
  def generate_schema_name(schema, content)
    data_name = schema['data'] || 'unknown'
    "crud_#{data_name}_#{Time.now.to_i}"
  end
  
  def generate_file_path(schema)
    data_name = schema['data'] || 'unknown'
    "api/views/#{data_name}_management.erb"
  end
end


