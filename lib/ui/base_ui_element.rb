# frozen_string_literal: true

class BaseUIElement
  attr_accessor :impl_type, :ui, :style, :script

  def initialize
    super
  end

  # @param [Symbol] type
  def set_type(type)
    @impl_type = type
  end

  def output

  end

end
