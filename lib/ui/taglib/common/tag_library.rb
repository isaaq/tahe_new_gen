# AX TAGS
# Flexible, extensible custom tag and template-parsing framework built
# around the Radius templating framework.
#
# TagLibrary - Composed of an AxContext and an AxParser, each library
#  class provides the direct interface for defining tags in a given context,
#  passing local variables to the parser, and managing the parsing process. Best
#  use calls for the application to create any number of descendant classes of
#  this class in which they define tags and call parsing actions upon. For
#  example:
#
#     class MyTagLibrary < AxTags::TagLibrary
#       tag "myanchor" do |t|
#         "<a class='awesome_anchor' href='http://awesometown.com/'>I am Awesome!</a>"
#       end
#     end
#
#     MyTagLibrary.parse("Here is an awesome link: <ax:myanchor/>")
#     => "Here is an awesome link: <a class='awesome_anchor' href='http://awesometown.com/'>I am awesome!</a>"
#
#  Because tags are defined at a class level, it's not generally recommended to
#  use the parent class as your API to tag definition and parsing, though it is
#  possible to access the context and parsers directly and define tags and call
#  parsing on them. That would look some like this:
#
#    AxTags::TagLibrary.context.with do |c|
#      c.define_tag "myanchor" do |t|
#        "<a class='awesome_anchor' href='http://awesometown.com/'>I am Awesome!</a>"
#      end
#    end
#    AxTags::TagLibrary.parse("Here is an awesome link: <ax:myanchor/>")
#    => "Here is an awesome link: <a class='awesome_anchor' href='http://awesometown.com/'>I am awesome!</a>"
#
# This introduces the complication of having only one global tag library in which
# all tags in your system would exist, which is why the first example is the preferred
# method for optimal extensibility and namespacing.
#

module Tags
  class TagLibrary
    def self.prefix(prefix)
      @tag_prefix = prefix
    end
    def self.context
      @@context ||= TagContext.new
    end

    def self.parse(document, options = {})
      if locals = options.delete(:locals)
        locals.each { |arg, value| context.globals.send("#{arg}=", value) }
      end
      tag_prefix = options.delete(:prefix)
      parser = TagParser.new(context, :tag_prefix => tag_prefix || @tag_prefix)
      o = parser.parse(document)
      @@context = parser.context
      o
    end

    def self.build_tags(&block)
      yield context
    end

    def self.tag(name, options = {}, &block)
      build_tags do |c|
        c.define_tag(name, options, &block)
      end
    end

  end
end
