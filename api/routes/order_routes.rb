require 'sinatra/base'

module OrderRoutes
  def self.registered(app)
    app.get '/api/v1/orders' do
      content_type :json
      
      begin
        # 获取请求体
        body = get_json_body
        
        # 获取用户信息
        user_id = get_prop_from_token('uid')
        halt 401, make_resp(nil, 'error', 40100, '用户未登录').to_json unless user_id
        
        # 获取分页参数
        page = (params[:page] || 1).to_i
        per_page = (params[:per_page] || 10).to_i
        
        # 构建查询条件
        query = { user_id: user_id }
        
        # 添加时间范围筛选
        if params[:start_time] && params[:end_time]
          begin
            start_time = Time.parse(params[:start_time])
            end_time = Time.parse(params[:end_time])
            query[:created_at] = { '$gte' => start_time, '$lte' => end_time }
          rescue ArgumentError
            halt 400, make_resp(nil, 'error', 40001, '无效的时间格式').to_json
          end
        end
        
        # 查询订单
        orders = M[:orders].find(query)
                          .sort(created_at: -1)
                          .skip((page - 1) * per_page)
                          .limit(per_page)
                          .to_a
        
        # 获取总数
        total = M[:orders].count(query)
        
        # 构建响应数据
        data = {
          orders: orders.map { |order|
            {
              id: order[:_id].to_s,
              status: order[:status],
              created_at: order[:created_at],
              updated_at: order[:updated_at]
            }
          },
          pagination: {
            page: page,
            per_page: per_page,
            total: total,
            total_pages: (total.to_f / per_page).ceil
          }
        }
        
        make_resp(data).to_json
      rescue => e
        make_resp(nil, 'error', 50000, e.message).to_json
      end
    end
  end
end
