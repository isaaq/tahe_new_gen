# frozen_string_literal: true

require 'sinatra/base'
require_relative '../../lib/plugins/store/plugin_store'
require_relative '../../lib/ai_services/plugin_assistant'

module PluginStoreRoutes
  def self.registered(app)
    # 列出所有插件
    app.get '/plugin-store/list' do
      content_type :json
      
      begin
        category = params['category']
        tags = params['tags'] ? params['tags'].split(',') : []
        is_builtin = params['is_builtin'] == 'true' ? true : (params['is_builtin'] == 'false' ? false : nil)
        installed = params['installed'] == 'true' ? true : (params['installed'] == 'false' ? false : nil)
        
        store = PluginStore.instance
        plugins = store.list_plugins(
          category: category,
          tags: tags,
          is_builtin: is_builtin,
          installed: installed
        )
        
        {
          status: 'success',
          count: plugins.size,
          plugins: plugins
        }.to_json
      rescue => e
        status 500
        {
          status: 'error',
          error: e.message,
          backtrace: e.backtrace.first(5)
        }.to_json
      end
    end
    
    # 搜索插件
    app.get '/plugin-store/search' do
      content_type :json
      
      begin
        keyword = params['keyword'] || params['q']
        return { status: 'error', error: 'Missing keyword parameter' }.to_json unless keyword
        
        store = PluginStore.instance
        plugins = store.search_plugins(keyword)
        
        {
          status: 'success',
          count: plugins.size,
          plugins: plugins
        }.to_json
      rescue => e
        status 500
        {
          status: 'error',
          error: e.message
        }.to_json
      end
    end
    
    # 获取插件详情
    app.get '/plugin-store/:id' do
      content_type :json
      
      begin
        plugin_id = params['id']
        version = params['version']
        
        store = PluginStore.instance
        plugin = store.get_plugin(plugin_id, version)
        
        if plugin
          {
            status: 'success',
            plugin: plugin
          }.to_json
        else
          status 404
          {
            status: 'error',
            error: 'Plugin not found'
          }.to_json
        end
      rescue => e
        status 500
        {
          status: 'error',
          error: e.message
        }.to_json
      end
    end
    
    # 安装插件
    app.post '/plugin-store/install' do
      content_type :json
      
      begin
        body = JSON.parse(request.body.read)
        plugin_id = body['plugin_id']
        version = body['version'] || 'latest'
        
        return { status: 'error', error: 'Missing plugin_id' }.to_json unless plugin_id
        
        store = PluginStore.instance
        result = store.install_plugin(plugin_id, version)
        
        if result[:success]
          {
            status: 'success',
            message: result[:message],
            plugin: result[:plugin]
          }.to_json
        else
          status 400
          {
            status: 'error',
            error: result[:error]
          }.to_json
        end
      rescue => e
        status 500
        {
          status: 'error',
          error: e.message,
          backtrace: e.backtrace.first(5)
        }.to_json
      end
    end
    
    # 卸载插件
    app.post '/plugin-store/uninstall' do
      content_type :json
      
      begin
        body = JSON.parse(request.body.read)
        plugin_id = body['plugin_id']
        
        return { status: 'error', error: 'Missing plugin_id' }.to_json unless plugin_id
        
        store = PluginStore.instance
        result = store.uninstall_plugin(plugin_id)
        
        if result[:success]
          {
            status: 'success',
            message: result[:message]
          }.to_json
        else
          status 400
          {
            status: 'error',
            error: result[:error]
          }.to_json
        end
      rescue => e
        status 500
        {
          status: 'error',
          error: e.message
        }.to_json
      end
    end
    
    # 获取已安装的插件列表
    app.get '/plugin-store/installed' do
      content_type :json
      
      begin
        store = PluginStore.instance
        installed = store.get_installed_plugins
        
        # 获取完整的插件信息
        plugins = installed.map do |installed_plugin|
          plugin = store.get_plugin(installed_plugin['plugin_id'], installed_plugin['version'])
          plugin || { plugin_id: installed_plugin['plugin_id'], version: installed_plugin['version'] }
        end
        
        {
          status: 'success',
          count: plugins.size,
          plugins: plugins
        }.to_json
      rescue => e
        status 500
        {
          status: 'error',
          error: e.message
        }.to_json
      end
    end
    
    # ========== AI辅助API ==========
    
    # AI推荐插件
    app.post '/plugin-store/recommend' do
      content_type :json
      
      begin
        body = JSON.parse(request.body.read)
        requirement = body['requirement'] || body['content']
        
        return { status: 'error', error: 'Missing requirement parameter' }.to_json unless requirement
        
        assistant = PluginAssistant.instance
        result = assistant.recommend_plugins(requirement)
        
        if result[:status] == 'success'
          {
            status: 'success',
            recommendations: result[:recommendations],
            optional: result[:optional],
            explanation: result[:explanation]
          }.to_json
        else
          status 400
          {
            status: 'error',
            error: result[:error] || 'AI recommendation failed'
          }.to_json
        end
      rescue => e
        status 500
        {
          status: 'error',
          error: e.message,
          backtrace: e.backtrace.first(5)
        }.to_json
      end
    end
    
    # AI辅助配置插件
    app.post '/plugin-store/configure' do
      content_type :json
      
      begin
        body = JSON.parse(request.body.read)
        plugin_id = body['plugin_id']
        user_input = body['user_input'] || body['input']
        
        return { status: 'error', error: 'Missing plugin_id or user_input' }.to_json unless plugin_id && user_input
        
        assistant = PluginAssistant.instance
        result = assistant.configure_plugin(plugin_id, user_input)
        
        if result[:status] == 'success'
          {
            status: 'success',
            config: result[:config],
            explanation: result[:explanation]
          }.to_json
        else
          status 400
          {
            status: 'error',
            error: result[:error] || 'AI configuration failed'
          }.to_json
        end
      rescue => e
        status 500
        {
          status: 'error',
          error: e.message
        }.to_json
      end
    end
    
    # AI推荐插件组合
    app.post '/plugin-store/combine' do
      content_type :json
      
      begin
        body = JSON.parse(request.body.read)
        requirements = body['requirements'] || body['requirement']
        
        return { status: 'error', error: 'Missing requirements parameter' }.to_json unless requirements
        
        assistant = PluginAssistant.instance
        result = assistant.suggest_plugin_combination(requirements)
        
        if result[:status] == 'success'
          {
            status: 'success',
            plugins: result[:plugins],
            installation_order: result[:installation_order],
            config_guide: result[:config_guide]
          }.to_json
        else
          status 400
          {
            status: 'error',
            error: result[:error] || 'AI combination recommendation failed'
          }.to_json
        end
      rescue => e
        status 500
        {
          status: 'error',
          error: e.message
        }.to_json
      end
    end
  end
end

