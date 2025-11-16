require_relative '../_system'
require_relative '../lib/util/common'

# 清理现有数据
# 使用正确的方法调用方式
Common::M['c_orgs'].del_many
Common::M['org_departments'].del_many
Common::M['org_positions'].del_many
Common::M['org_employees'].del_many

puts "已清理现有组织结构数据"

# 创建测试组织
org_data = {
  name: '测试公司',
  code: 'TEST001',
  type: '公司',
  description: '这是一个测试公司',
  status: true,
  created_at: Time.now,
  updated_at: Time.now
}

org_id = Common::M['c_orgs'].add(org_data).inserted_id
puts "创建组织: #{org_data[:name]}, ID: #{org_id}"

# 创建子公司
sub_org_data = {
  name: '测试子公司',
  code: 'TEST002',
  type: '子公司',
  description: '这是一个测试子公司',
  parent_id: org_id,
  path: "/#{org_id}/",
  level: 2,
  status: true,
  created_at: Time.now,
  updated_at: Time.now
}

sub_org_id = Common::M['c_orgs'].add(sub_org_data).inserted_id
puts "创建子公司: #{sub_org_data[:name]}, ID: #{sub_org_id}"

# 创建部门
dept_data = {
  name: '研发部',
  code: 'RD001',
  org_id: org_id,
  description: '负责产品研发',
  status: true,
  level: 1,
  path: "/#{org_id}/",
  created_at: Time.now,
  updated_at: Time.now
}

dept_id = Common::M['org_departments'].add(dept_data).inserted_id
puts "创建部门: #{dept_data[:name]}, ID: #{dept_id}"

# 创建子部门
sub_dept_data = {
  name: '前端组',
  code: 'RD002',
  org_id: org_id,
  parent_id: dept_id,
  description: '负责前端开发',
  status: true,
  level: 2,
  path: "/#{dept_id}/",
  created_at: Time.now,
  updated_at: Time.now
}

sub_dept_id = Common::M['org_departments'].add(sub_dept_data).inserted_id
puts "创建子部门: #{sub_dept_data[:name]}, ID: #{sub_dept_id}"

# 创建职位
positions = [
  {
    name: '技术总监',
    code: 'TD001',
    org_id: org_id,
    description: '负责技术团队管理',
    level: 5,
    status: true,
    created_at: Time.now,
    updated_at: Time.now
  },
  {
    name: '高级工程师',
    code: 'SE001',
    org_id: org_id,
    description: '负责核心技术开发',
    level: 4,
    status: true,
    created_at: Time.now,
    updated_at: Time.now
  },
  {
    name: '前端工程师',
    code: 'FE001',
    org_id: org_id,
    description: '负责前端开发',
    level: 3,
    status: true,
    created_at: Time.now,
    updated_at: Time.now
  }
]

position_ids = []
positions.each do |position|
  position_id = Common::M['org_positions'].add(position).inserted_id
  position_ids << position_id
  puts "创建职位: #{position[:name]}, ID: #{position_id}"
end

# 创建员工
employees = [
  {
    name: '张三',
    employee_id: 'EMP001',
    org_id: org_id,
    department_id: dept_id,
    position_id: position_ids[0],
    email: 'zhangsan@example.com',
    phone: '13800138000',
    gender: '男',
    status: '在职',
    is_leader: true,
    entry_date: Time.now,
    created_at: Time.now,
    updated_at: Time.now
  },
  {
    name: '李四',
    employee_id: 'EMP002',
    org_id: org_id,
    department_id: dept_id,
    position_id: position_ids[1],
    email: 'lisi@example.com',
    phone: '13900139000',
    gender: '男',
    status: '在职',
    entry_date: Time.now,
    created_at: Time.now,
    updated_at: Time.now
  },
  {
    name: '王五',
    employee_id: 'EMP003',
    org_id: org_id,
    department_id: sub_dept_id,
    position_id: position_ids[2],
    email: 'wangwu@example.com',
    phone: '13700137000',
    gender: '男',
    status: '在职',
    is_leader: true,
    entry_date: Time.now,
    created_at: Time.now,
    updated_at: Time.now
  }
]

employees.each do |employee|
  employee_id = Common::M['org_employees'].add(employee).inserted_id
  puts "创建员工: #{employee[:name]}, ID: #{employee_id}"
end

puts "初始化组织结构数据完成！"
