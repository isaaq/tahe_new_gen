require 'sinatra'
require 'sinatra/base'
require 'sinatra/content_for'
require 'sinatra/cookies'
require 'sinatra/flash'
require 'sinatra/reloader' if development?
require 'sinatra/namespace'

require 'redis'

require 'jwt'
require 'letsaboard'

require_relative './_system'
require_relative './lib/util/common'
require_relative './lib/model/_config'
require_relative './lib/biz/_config'

Dir.glob(["./api/_config.rb"]).each {|file| "装载配置#{file}" if development?; require_relative file}

map('/api') {run TaheController}
map('/sys') {run SystemController}

