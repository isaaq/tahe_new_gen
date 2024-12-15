class BaseType
  # attr_accessor :base
  class << self
    attr_accessor :_name, :base
    def reg(name)
      @_name = name
    end

    def show(name, length)
      @base = Object.const_get(name.capitalize).new
      @base.run
    end
  end
end
