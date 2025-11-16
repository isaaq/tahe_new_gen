require_relative '../_system'
require_relative '../lib/util/common'
require 'bson'

# 获取组织ID
org_id = ARGV[0]
if org_id.nil? || org_id.empty?
  puts "请提供组织ID作为参数"
  exit 1
end

begin
  # 检查组织是否存在
  org = Common::M['c_orgs'].query({ _id: BSON::ObjectId(org_id) }).first
  unless org
    puts "组织不存在: #{org_id}"
    exit 1
  end
  
  # 创建测试部门数据
  departments = [
    {
      _id: BSON::ObjectId.new,
      name: '研发部',
      code: 'RD',
      description: '负责产品研发',
      parent_id: nil,
      org_id: org_id,
      path: "/#{org_id}/",
      level: 1,
      sort_order: 1,
      status: true,
      created_at: Time.now,
      updated_at: Time.now
    },
    {
      _id: BSON::ObjectId.new,
      name: '市场部',
      code: 'MKT',
      description: '负责市场营销',
      parent_id: nil,
      org_id: org_id,
      path: "/#{org_id}/",
      level: 1,
      sort_order: 2,
      status: true,
      created_at: Time.now,
      updated_at: Time.now
    },
    {
      _id: BSON::ObjectId.new,
      name: '财务部',
      code: 'FIN',
      description: '负责财务管理',
      parent_id: nil,
      org_id: org_id,
      path: "/#{org_id}/",
      level: 1,
      sort_order: 3,
      status: true,
      created_at: Time.now,
      updated_at: Time.now
    }
  ]
  
  # 插入部门数据
  departments.each do |dept|
    Common::M['org_departments'].add(dept)
    puts "已添加部门: #{dept[:name]}"
  end
  
  puts "成功添加测试部门数据"
rescue => e
  puts "错误: #{e.message}"
  exit 1
end
