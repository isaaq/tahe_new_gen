# frozen_string_literal: true

class TransBuilder

  def parse_ui(file)
    xmlfile = Nokogiri::XML(file)
    script_data = []
    ns = xmlfile.xpath('component/displayList/*').each do |ele|
      cb = FGUIElementBuilder.new(ele)
      ele.name = cb.build_ele_name
      ele[':config'] = cb.build_cfg
      script_data += cb.build_data
    end
    return ns, script_data
  end

  def make_out(olddoc, script_data)
    # eles = olddoc.xpath('compontent/displaylist//*')
    fragment = Nokogiri::HTML.fragment('')
    Nokogiri::HTML::Builder.with(fragment) do |f|
      f.template {
        olddoc.each do |ele|
          # f.div(ele.attributes) {
          #   ele.children.each do |child|
          #     f << child
          #   end
          # }
          f.send(ele.name.to_sym, ele.attributes) {
            # ele.children.each do |child|
            #   f << child
            # end
          }
        end
      }
      script = <<~JS
        export default {
          components: {
            
          },
          data: function() {
             imglist: [],
             #{script_data}
          }
        }
      JS
      f.script(script)

    end

    # out = Nokogiri::HTML::Builder.new do |doc|
    #   doc.html {
    #     doc.template {
    #
    #     }
    #     doc.script {
    #
    #     }
    #   }
    # end
    out = fragment.to_html.gsub(/<\/?html>/, '')
    File.write('out.html', out)
  end
end
