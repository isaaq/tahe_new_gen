class TaheController < ApiController
  get '/sys/funcs/:id' do
    f = M[:_脚本].query(_id: _params[:id]).to_a
    f.to_resp
  end

end

