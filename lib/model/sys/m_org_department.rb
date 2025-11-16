class MOrgDepartment
  extend SysModelCommon
  表 :org_departments
  名 :_部门
  型 :部门
  构 [
       { Text: ['name', '名称', { is_global_search: true }] },
       { Text: ['code', '部门编码', { is_global_search: true }] },
       { Text: ['description', '描述'] },
       { Link: ['parent_id', '上级部门', { link_to: 'MOrgDepartment' }] },
       { Link: ['org_id', '所属组织', { link_to: 'MCOrg' }] },
       { Text: ['path', '部门路径', { is_system: true }] }, # 存储部门的完整路径，如 /1/2/3/
       { Number: ['level', '层级', { is_system: true }] }, # 部门的层级，根部门为1
       { Number: ['sort_order', '排序', { default: 0 }] },
       { Boolean: ['status', '状态', { default: true }] },
       { DateTime: ['created_at', '创建时间', { is_system: true }] },
       { DateTime: ['updated_at', '更新时间', { is_system: true }] }
     ]
end
