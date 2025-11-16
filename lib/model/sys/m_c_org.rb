class MCOrg
  extend SysModelCommon
  表 :c_orgs
  名 :_组织
  型 :组织
  构 [
       { Text: ['name', '名称', { is_global_search: true }] },
       { Text: ['code', '组织编码', { is_global_search: true }] },
       { Enum: ['type', '类型', { values: ['公司', '子公司', '分公司', '部门'], default: '公司' }] },
       { Text: ['description', '描述'] },
       { Text: ['logo', '组织Logo', { is_file: true }] },
       { Text: ['address', '地址'] },
       { Text: ['contact', '联系人'] },
       { Text: ['phone', '联系电话'] },
       { Text: ['email', '联系邮箱'] },
       { Link: ['parent_id', '上级组织', { link_to: 'MCOrg' }] },
       { Text: ['path', '组织路径', { is_system: true }] }, # 存储组织的完整路径，如 /1/2/3/
       { Number: ['level', '层级', { is_system: true }] }, # 组织的层级，根组织为1
       { Number: ['sort_order', '排序', { default: 0 }] },
       { Boolean: ['status', '状态', { default: true }] },
       { DateTime: ['created_at', '创建时间', { is_system: true }] },
       { DateTime: ['updated_at', '更新时间', { is_system: true }] }
     ]
end
