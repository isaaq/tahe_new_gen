class WebTool < Thor
  desc 'make wasm'
  def make_wasm
    `mec `
  end
end