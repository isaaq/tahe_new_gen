# frozen_string_literal: true

class FormTag < LayuiElement
    def elename
        'f'
    end



    def output_tag
        "<#{prefix}:#{elename}>#{@children}</#{prefix}:#{elename}>"
    end
end
