# frozen_string_literal: true

require_relative '../../../../util/common_func'

module TagHelper
  include Common

  module RegTag
    # 为 tag 生成 id 的方法
    def kr_id(tag)
      tag.attr['id'] || "#{tag.name}_#{gen_id}"
    end

    # 更新上下文的方法
    def make_ctx(tag, id = nil, parent_id = nil)
      tag.attr['id'] = id unless id.nil?
      @context ||= {}
      if !id.nil? && parent_id.nil?
        @context[id.to_sym] ||= []
        @context[id.to_sym] = { type: tag.name }.merge(tag.attr.transform_keys(&:to_sym))
      end
      return if parent_id.nil?

      @context[parent_id.to_sym][tag.name.to_sym] ||= []
      @context[parent_id.to_sym][tag.name.to_sym] << { type: tag.name }.merge(tag.attr.transform_keys(&:to_sym))
    end

    # 生成目标对象的方法
    def make_target(tag, prefix, children = nil)
      Object.const_get(prefix.to_s.capitalize + 'Transformer').trans(tag, @context, children)
    end

    # 注册根级标签
    def register_root_tag(type, *names)
      names.each do |name|
        tag name do |tg|
          setup_root_tag(tg, type)
        end
      end
    end

    # 注册子级标签
    def register_child_tag(type, *names)
      names.each do |name|
        tag name do |tg|
          setup_parent_tag(tg, type)
        end
      end
    end

    # 设置根级标签的逻辑
    def setup_root_tag(tag, type)
      id = tag.attr['id'] || "#{tag.name}_#{SecureRandom.hex(4)}"
      make_ctx(tag, id)
      make_target(tag, type, tag.expand)
    end

    # 设置子级标签的逻辑
    def setup_parent_tag(tag, type)
      parent_id = tag.parent['id']
      id = tag.attr['id'] || "#{tag.name}_#{SecureRandom.hex(4)}"
      make_ctx(tag, id, parent_id)
      make_target(tag, type, tag.expand)
    end
  end

  # 自动扩展功能
  def self.included(base)
    base.include RegTag
  end
end

module Radius
  class Context
    def parent
      @tag_binding_stack[-2] || {}
    end
  end

  class TagBinding
    def parent
      @context.parent
    end
  end

  class Scanner
    def operate(prefix, data)
      data = data.force_encoding('UTF-8')  # Force UTF-8 encoding
      data = Radius::OrdString.new data
      @nodes = ['']
      
      re = scanner_regex(prefix)
      if md = re.match(data)      
        remainder = ''  
        while md
          start_tag, attributes, self_enclosed, end_tag = $1, $2, $3, $4

          flavor = self_enclosed == '/' ? :self : (start_tag ? :open : :close)
          
          pos = md.begin(0)
          attrs = parse_attributes(attributes)
          # 找到匹配位置之前的所有文本
          preceding_text = data[(pos<200?0:pos-200)...pos]
          # 通过正则找到匹配前的最后一行
          previous_line = preceding_text[/.*\n?$/]&.chomp
          attrs['objtree'] = previous_line if previous_line.match(/\/\/\[.+?\]\/\//)

          # save the part before the current match as a string node
          @nodes << (attrs['objtree'] ? md.pre_match.gsub(previous_line, '') : md.pre_match)
          # save the tag that was found as a tag hash node
          @nodes << {:prefix=>prefix, :name=>(start_tag || end_tag), :flavor => flavor, :attrs => attrs}
          
          # remember the part after the current match
          remainder = md.post_match
          # see if we find another tag in the remaining string
          md = re.match(md.post_match)
        end  
        
        # add the last remaining string after the last tag that was found as a string node
        @nodes << remainder
      else
        @nodes << data
      end

      return @nodes
    end
  end
end
