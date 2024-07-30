require 'forwardable'
require 'mongo'
require 'mongo/retryable'

module BSON
  class ObjectId
    def to_json(*args)
      to_s.to_json
    end

    def as_json(*args)
      to_s.as_json
    end
  end
end

class Object
  # @return [BSON::ObjectId]
  def to_objid
    if self.is_a?(String)
      begin
        BSON::ObjectId(self)
      rescue
        self
      end
    elsif self.is_a?(BSON::ObjectId)
      self
    else
      raise ConflictError, '转换不了ObjectId，格式不对'
    end
  end
end