class TaheController < ApiController
  get '/ui/main' do
    content_type :html
    f = File.read('web/tpl/index.html')

    # @opal = Opal::Sprockets.javascript_include_tag('ui/web')
    erb(f)
  end

  get '/ui/templates' do
    M[:node_templates].query.projection(data: 0).to_a.to_resp
  end

  get '/ui/template/:name' do
    M[:node_templates].query(name: _params[:name]).to_a[0][:data].to_json
  end

  get '/ui/types' do
    M[:node_types].query.to_a.map do |m|
      m[:content] = Base64.decode64(m[:content])
      m
    end.to_resp
  end

  get '/ui/test' do
    content_type :html
    UIPage.new(:layui).parse(layout: :default)
  end

  get '/ui/test2' do
    content_type :html
    UIPage.new(:vue).parse
  end
end
