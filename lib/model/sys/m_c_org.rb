class MCOrg
  extend SysModelCommon
  表 :c_orgs
  名 :_组织
  型 :组织
  构 [
       Text: ['name', '名称', { is_global_search: true }],
       Enum: ['type', '类型']
     ]
end

