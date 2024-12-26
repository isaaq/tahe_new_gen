# frozen_string_literal: true

class InputTarget < LayuiElementTarget
    def elename
        'f'
    end

    def output_target
        tag.attributes
        "<input />"
    end
end 