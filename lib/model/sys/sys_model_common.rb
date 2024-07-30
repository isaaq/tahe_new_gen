module SysModelCommon
  def _table(tbl_name = nil)
    @table = tbl_name unless tbl_name.nil?
    @table
  end

  def _name(name = nil)
    @name = name unless name.nil?
    @name
  end

  def _type(*names)
    @type = names unless names.nil?
    @type
  end

  def _structure(hash = nil)
    unless hash.nil?
      @struct_list ||= []
      hash&.at(0)&.each do |k, v|
        begin
          clz = Object.const_get(k)
          inst = clz.new
          @struct_list << inst
        rescue Exception => e
          @_err ||= []
          @_err << {err: e, obj: [k,v]}
          if Common::C[:log_err] == 1
            Common::M[:log_errors].add({type:'model_error', msg: e.to_s, obj: [k,v]})
          end
        end
      end
    end
    @struct_list
  end

  alias :表 :_table
  alias :名 :_name
  alias :型 :_type
  alias :构 :_structure
end
