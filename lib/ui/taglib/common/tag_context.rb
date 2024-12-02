# AX TAGS
# Flexible, extensible custom tag and template-parsing framework built
# around the Radius templating framework.
#
# AxContext - A context contains a dictionary of tags that can be used
#  in template parsing. Context objects are passed to parsers alongside
#  templates to enable parsing.
#

module Tags
  class TagContext < Radius::Context

    # A catch-call for handling an unsupported tag included in a template:
    def tag_missing(tag, attr, &block)
      %{<span class="error parse-error ui-state-error">Tag "#{tag}" is unknown. Attributes provided: #{attr.inspect}</span>}
    end

    # A method in-reserve for generic error-reporting to the end-user:
    def tag_error(tag, error_text)
      %{<span class="error parse-error ui-state-error">Error in rendering tag \"#{tag}\"; #{error_text}</span>}
    end

  end
end
