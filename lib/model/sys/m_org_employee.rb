class MOrgEmployee
  extend SysModelCommon
  表 :org_employees
  名 :_员工
  型 :员工
  构 [
       { Text: ['employee_id', '工号', { is_global_search: true }] },
       { Text: ['name', '姓名', { is_global_search: true }] },
       { Link: ['user_id', '用户账号', { link_to: 'MRbacUser' }] },
       { Link: ['org_id', '所属组织', { link_to: 'MCOrg' }] },
       { Link: ['department_id', '所属部门', { link_to: 'MOrgDepartment' }] },
       { Link: ['position_id', '职位', { link_to: 'MOrgPosition' }] },
       { Text: ['email', '邮箱'] },
       { Text: ['phone', '手机号'] },
       { Text: ['avatar', '头像', { is_file: true }] },
       { Enum: ['gender', '性别', { values: ['男', '女', '未知'], default: '未知' }] },
       { Date: ['entry_date', '入职日期'] },
       { Date: ['leave_date', '离职日期'] },
       { Enum: ['status', '状态', { values: ['在职', '离职', '试用期'], default: '在职' }] },
       { Text: ['job_title', '职称'] },
       { Text: ['work_place', '工作地点'] },
       { Boolean: ['is_leader', '是否部门负责人', { default: false }] },
       { DateTime: ['created_at', '创建时间', { is_system: true }] },
       { DateTime: ['updated_at', '更新时间', { is_system: true }] }
     ]
end
