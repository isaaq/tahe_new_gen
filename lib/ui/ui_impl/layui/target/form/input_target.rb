# frozen_string_literal: true

class InputTarget < LayuiElementTarget
  def elename
    'f'
  end

  def output_target
    attr = tag.attributes
    if @tag['objtree']
      json = kr_get_objtree(@tag['objtree'])

      <<~CODE
       <input id="#{json[:id]}"/>
      CODE
    else
      <<~CODE
        <input id="#{tag['id']}"/>
      CODE
      # TODO 没有objtree的话 需要解析标签
    end
  end
end 