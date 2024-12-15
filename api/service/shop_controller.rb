# frozen_string_literal: true

class TaheController < ApiController
  post '/shop/cate_children_with_goods/:id' do
    id = params[:id]
    children = M[:b_cates].query(pid: id).to_a
    children.map! do |m|
      shop = M[:b_shops].query(cate_id: m[:_id].to_s).to_a[0]
      if !shop.nil?
        g = M[:b_goods].query(shop_id: shop[:_id].to_s).to_a
        m[:goods] = g
      end
      m
    end
    children.to_resp
  end

  post '/shop/cate_children/:id' do
    id = params[:id]
    children = M[:b_cates].query(pid: id).to_a
    children.map! do |m|
      shops = M[:b_shops].query(cate_id: m[:_id].to_s).to_a
      m[:children] = shops
      m
    end
    children.to_resp
  end

  get '/goods/:sid' do
    M[:b_goods].query(shop_id: params[:sid]).to_a.to_resp

  end

end

