class TName < BaseType
  reg :名
  show :text, 20

  def build
    self.class.base.run
  end

  private
  def first_name
    # value.match()
  end
end
