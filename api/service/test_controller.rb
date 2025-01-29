class TaheController < ApiController
  
  get '/test' do
    'test'.to_resp
  end

  get '/test_func' do

  end

  get '/test_query' do
    # p _user
    # p _roles
    # p _scopes
    M.load_path = 'test/data/dsl/model'
    M.user = _user
    M[:订单].query.to_a
  end

end

