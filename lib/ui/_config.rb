require 'radius'
cur_path = File.dirname(__FILE__)
load_files("#{cur_path}")
require_relative("#{cur_path}/taglib/_config")
load_files("#{cur_path}/ui_impl/layui")
load_all_files("#{cur_path}/ui_impl")