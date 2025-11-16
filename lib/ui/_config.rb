require 'radius'
cur_path = File.dirname(__FILE__)
load_files("#{cur_path}")
require_relative("#{cur_path}/taglib/_config")

# 加载UI配置系统
require_relative("#{cur_path}/config/_init")

# 加载模板系统
require_relative("#{cur_path}/../templates/_init")

load_files("#{cur_path}/ui_impl/layui")
load_all_files("#{cur_path}/ui_impl")