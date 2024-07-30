def dev
  true
end

def load_all_files(path)
  # dev = false
  Dir["#{path}/**/*.rb"].sort.each { |f| (p "装载文件#{f}" if dev; require(f)) if !f.include?('_config.rb') }
end

def load_files(path)
  # dev = false
  Dir["#{path}/*.rb"].each { |f| (p "装载文件#{f}" if dev; require(f); yield(f) if block_given?) if !f.include?('_config.rb') }
end
require 'singleton'
class Global
  include Singleton
  # class << Global
    attr_accessor :_record_inherited_flag, :_sys_models
  # end
end


class Object
  def self.inherited(subclass)
    if Global.instance._record_inherited_flag
      (@classes ||= []) << subclass
    end
  end
  def self.fetch_loaded_classes
    out = @classes.dup
    @classes = []
    out
  end
end