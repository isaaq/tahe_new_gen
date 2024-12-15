require_relative './sys_model_common'
Global.instance._record_inherited_flag = true
load_files(File.dirname(__FILE__))
Global.instance._record_inherited_flag = false
loaded = self.class.fetch_loaded_classes
loaded.each do |clazz|
  clazz.extend SysModelCommon
  # clazz.new.test
  #
  (Global.instance._sys_models ||= []) << clazz
end