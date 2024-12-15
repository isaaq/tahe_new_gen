class FGUIElementBuilder
  attr_accessor :ele, :origin_ele, :type, :cfg_item_list, :script_data

  def initialize(ele)
    @origin_ele = ele
    @ele = ele.dup
    del_attrs(@origin_ele)
    feature
    type
    @cfg_item_list = []
    @script_data = []

  end

  def build_cfg
    process
    "{#{@cfg_item_list.join(',')}}"
  end

  def build_data
    @script_data
    end

  def build_ele_name
    @type_name
  end

  private

  def type
    name = @ele.name
    dict = { image: 'v-image', loader: 'div', text: 'v-text' }
    if dict[name.to_sym].nil?
      if name == 'graph'
        @type = @ele['type']
        @type_name = "v-#{@type}"
      elsif name == 'component'
        ctl = @ele['fileName'].split('/')[1].split('.')[0]
        @type = @type_name = ctl
      else
        @type = @type_name = name
      end
    else
      @type = name
      @type_name = dict[name.to_sym]
    end

  end

  def process
    # common_process
    unless ele['xy'].nil?
      xy = ele['xy'].split(',')
      @cfg_item_list << "x: #{xy[0]}"
      @cfg_item_list << "y: #{xy[1]}"
    end
    unless ele['size'].nil?
      size = ele['size'].split(',')
      @cfg_item_list << "width: #{size[0]}"
      @cfg_item_list << "height: #{size[0]}"
    end
    @file = ele['fileName']
    case @type
    when 'image'
      the_img = @ele['id']
      @cfg_item_list << "image: imglist['#{the_img}']"
      @script_data << ""
    when 'loader'

    else

    end
  end

  def del_attrs(ele)
    ele.traverse do |node|
      node.keys.each do |attribute|
        node.delete attribute
      end
    end
  end
  def feature
    @features = []
    @origin_ele.children.each do |child|
      #parse feature
      unless child.is_a?(Nokogiri::XML::Text)
        case child.name
        when 'relation'
          # TODO relation 部分
        else
          raise "unknown feature #{child.name}"
        end
        @features << child
      end
      child.remove
    end
  end

end