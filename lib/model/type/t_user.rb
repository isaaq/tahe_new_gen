class TPerson < BaseType
  reg :人
  show :text, 20

  def build
    p '人'
    self.class.base.run
  end

  private
  def first_name
    # value.match()
  end
end
