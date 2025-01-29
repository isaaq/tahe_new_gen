# 错误码
module ErrorCode
  COMMON = 0
  ACCOUNT = 10000
  PERMISSION = 20000
  BIZ = 30000
  SYS = 90000
end


class CommonError < StandardError

end

class AccountError < CommonError
  def initialize(msg, code)
    super("账户异常#{code}：#{msg}")
  end
end