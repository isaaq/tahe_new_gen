require 'thor'
require 'tmpdir'
require 'nokogiri'
require 'json'
require_relative 'tool_common'
require_relative 'trans_ele_builder'
require_relative 'trans_builder'
class TransFGUI < Thor
  desc 'trans', '转换器'

  def trans(path)
    file = File.read(path)
    tb = TransBuilder.new
    ns, script_data = tb.parse_ui(file)
    tb.make_out(ns, script_data.join("\n"))
  end

  desc 'trans_all', '转换器'
  def trans_all(folder)
    cfg = Nokogiri::XML(File.read("#{folder}/package.xml"))
    cfg.xpath('/packageDescription/resources/*').each do |ele|
      e = folder + ele['path'] + ele['name']
      trans(e)
    end
  end
end

TransFGUI.start(ARGV)
