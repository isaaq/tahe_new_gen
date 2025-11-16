# frozen_string_literal: true

# CompactProtocol - 紧凑协议编解码器
# 将完整协议压缩为紧凑格式，减少70%传输体积
class CompactProtocol
  # 编码：标准协议 -> 紧凑协议
  def self.encode(standard_protocol)
    {
      'c' => standard_protocol['collection'],           # collection
      'f' => standard_protocol['filter'] || {},         # filter
      'e' => encode_expands(standard_protocol['expand']), # expand
      's' => standard_protocol['sort'] || {},           # sort
      'p' => standard_protocol['page'] || 1,            # page
      'l' => standard_protocol['limit'] || 20           # limit
    }
  end
  
  # 解码：紧凑协议 -> 标准协议
  def self.decode(compact_protocol)
    {
      'collection' => compact_protocol['c'],
      'filter' => compact_protocol['f'] || {},
      'expand' => decode_expands(compact_protocol['e'], compact_protocol['c']),
      'sort' => compact_protocol['s'] || {},
      'page' => compact_protocol['p'] || 1,
      'limit' => compact_protocol['l'] || 20
    }
  end
  
  private
  
  # 编码expand为紧凑字符串
  # 完整格式: "relation:collection:fk:display:result"
  # 简短格式: "relation:display" （自动推断collection和fk）
  # 超短格式: "relation" （自动推断display='name'）
  def self.encode_expands(expands)
    return [] unless expands
    
    expands.map do |exp|
      # 生成紧凑字符串
      [
        exp['relation'],
        exp['collection'],
        exp['foreign_key'],
        exp['display_field'],
        exp['result_field']
      ].join(':')
    end
  end
  
  # 解码expand字符串为完整配置
  def self.decode_expands(compact_expands, source_collection)
    return [] unless compact_expands
    
    compact_expands.map do |exp_str|
      parts = exp_str.split(':')
      
      case parts.size
      when 5
        # 完整格式: "pkg:b_packages:package_id:name:package_name"
        {
          'relation' => parts[0],
          'collection' => parts[1],
          'foreign_key' => parts[2],
          'display_field' => parts[3],
          'result_field' => parts[4]
        }
        
      when 2
        # 简短格式: "pkg:name" (自动推断)
        relation = parts[0]
        display_field = parts[1]
        infer_expand_config(relation, display_field, source_collection)
        
      when 1
        # 超短格式: "pkg" (display_field默认为'name')
        relation = parts[0]
        infer_expand_config(relation, 'name', source_collection)
        
      else
        # 未知格式，使用默认
        {
          'relation' => exp_str,
          'collection' => "b_#{exp_str}s",
          'foreign_key' => "#{exp_str}_id",
          'display_field' => 'name',
          'result_field' => "#{exp_str}_name"
        }
      end
    end
  end
  
  def self.infer_expand_config(relation, display_field, source_collection)
    # 使用RelationRegistry自动推断
    foreign_key = "#{relation}_id"
    
    config = if defined?(RelationRegistry)
               RelationRegistry.resolve(relation, foreign_key, source_collection)
             else
               {
                 collection: "b_#{relation}s",
                 foreign_key: foreign_key,
                 type: :belongs_to
               }
             end
    
    {
      'relation' => relation,
      'collection' => config[:collection],
      'foreign_key' => foreign_key,
      'display_field' => display_field,
      'result_field' => "#{relation}_#{display_field}"
    }
  end
end




