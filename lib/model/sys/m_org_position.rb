class MOrgPosition
  extend SysModelCommon
  表 :org_positions
  名 :_职位
  型 :职位
  构 [
       { Text: ['name', '职位名称', { is_global_search: true }] },
       { Text: ['code', '职位编码', { is_global_search: true }] },
       { Text: ['description', '职位描述'] },
       { Link: ['org_id', '所属组织', { link_to: 'MCOrg' }] },
       { Number: ['level', '职级', { default: 1 }] }, # 职位级别，数字越大级别越高
       { Number: ['sort_order', '排序', { default: 0 }] },
       { Boolean: ['status', '状态', { default: true }] },
       { DateTime: ['created_at', '创建时间', { is_system: true }] },
       { DateTime: ['updated_at', '更新时间', { is_system: true }] }
     ]
end
