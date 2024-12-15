class BAuth
  include Common
  attr_accessor :token

  def self.take(token)
    @token = token
  end

  def get_role_list
    M[:_角色].query.to_a
  end

  def get_auth_list

  end

  def get_group_list

  end

  def self.get_org_list
    组织列表 = M[:_组织].query.to_a
    组织列表
  end
end
