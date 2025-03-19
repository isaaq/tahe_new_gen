require 'sinatra'
require 'sinatra/base'
require 'sinatra/content_for'
require 'sinatra/cookies'
require 'sinatra/flash'
require 'sinatra/reloader' if development?
require 'sinatra/namespace'
require 'redis'

require 'opal'
require 'opal-jquery'
require 'opal-sprockets'
require 'faraday'
require 'jwt'
require 'letsaboard'

require_relative './_system'
require_relative './lib/util/common'
require_relative './lib/model/_config'
require_relative './lib/biz/_config'
require_relative './lib/middleware/static_pages_middleware'

Dir.glob(['./api/_config.rb']).each do |file|
  "装载配置#{file}" if development?
  require_relative file
end
Opal::Config.esm = true
Opal::Config.source_map_enabled = false
opal = (Opal::Sprockets::Server.new do |s|
  s.append_path 'lib'
  s.main = 'web'
end)
Opal::Sprockets.javascript_include_tag('ui/web', sprockets: opal.sprockets, prefix: 'assets', debug: false)
map '/assets' do
  run opal.sprockets
end

# 使用静态页面中间件
use StaticPagesMiddleware, {
  enabled: ENV['USE_STATIC_PAGES'] == 'true',
  static_dir: File.join(File.dirname(__FILE__), 'web/static'),
  excluded_paths: ['/api/', '/sys/', '/assets/']
}

map('/api') { run TaheController }
map('/sys') { run SystemController }
