# frozen_string_literal: true

module KrTagHelper
  include TagHelper

  def self.extended(base)
    # p base
    # p base.instance_variable_get(:@tag_prefix)
  end
end
