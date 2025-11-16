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
  
  # 创建测试职位数据
  positions = [
    {
      _id: BSON::ObjectId.new,
      name: '总经理',
      code: 'GM',
      description: '公司最高管理者',
      org_id: org_id,
      level: 5,
      sort_order: 1,
      status: true,
      created_at: Time.now,
      updated_at: Time.now
    },
    {
      _id: BSON::ObjectId.new,
      name: '部门经理',
      code: 'DM',
      description: '部门负责人',
      org_id: org_id,
      level: 4,
      sort_order: 2,
      status: true,
      created_at: Time.now,
      updated_at: Time.now
    },
    {
      _id: BSON::ObjectId.new,
      name: '高级工程师',
      code: 'SE',
      description: '高级技术人员',
      org_id: org_id,
      level: 3,
      sort_order: 3,
      status: true,
      created_at: Time.now,
      updated_at: Time.now
    },
    {
      _id: BSON::ObjectId.new,
      name: '工程师',
      code: 'ENG',
      description: '技术人员',
      org_id: org_id,
      level: 2,
      sort_order: 4,
      status: true,
      created_at: Time.now,
      updated_at: Time.now
    }
  ]
  
  # 插入职位数据
  positions.each do |pos|
    Common::M['org_positions'].add(pos)
    puts "已添加职位: #{pos[:name]}"
  end
  
  puts "成功添加测试职位数据"
rescue => e
  puts "错误: #{e.message}"
  exit 1
end
