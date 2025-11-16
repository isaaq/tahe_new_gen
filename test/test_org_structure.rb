require 'minitest/autorun'
require 'rack/test'
require_relative '../lib/model/_config'
require_relative '../lib/model/sys/m_c_org'
require_relative '../lib/model/sys/m_org_department'
require_relative '../lib/model/sys/m_org_position'
require_relative '../lib/model/sys/m_org_employee'
require_relative '../lib/util/common'

class TestOrgStructure < Minitest::Test
  def setup
    # 清理测试数据
    Common::M.delete_many('c_orgs', {})
    Common::M.delete_many('org_departments', {})
    Common::M.delete_many('org_positions', {})
    Common::M.delete_many('org_employees', {})
  end

  def teardown
    # 清理测试数据
    Common::M.delete_many('c_orgs', {})
    Common::M.delete_many('org_departments', {})
    Common::M.delete_many('org_positions', {})
    Common::M.delete_many('org_employees', {})
  end

  def test_create_org
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
    
    org_id = Common::M.insert_one('c_orgs', org_data).inserted_id
    
    # 验证组织是否创建成功
    org = Common::M.find_one('c_orgs', { _id: org_id })
    assert_equal '测试公司', org['name']
    assert_equal 'TEST001', org['code']
    
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
    
    dept_id = Common::M.insert_one('org_departments', dept_data).inserted_id
    
    # 验证部门是否创建成功
    dept = Common::M.find_one('org_departments', { _id: dept_id })
    assert_equal '研发部', dept['name']
    assert_equal 'RD001', dept['code']
    
    # 创建职位
    position_data = {
      name: '软件工程师',
      code: 'SE001',
      org_id: org_id,
      description: '负责软件开发',
      level: 3,
      status: true,
      created_at: Time.now,
      updated_at: Time.now
    }
    
    position_id = Common::M.insert_one('org_positions', position_data).inserted_id
    
    # 验证职位是否创建成功
    position = Common::M.find_one('org_positions', { _id: position_id })
    assert_equal '软件工程师', position['name']
    assert_equal 'SE001', position['code']
    
    # 创建员工
    employee_data = {
      name: '张三',
      employee_id: 'EMP001',
      org_id: org_id,
      department_id: dept_id,
      position_id: position_id,
      email: 'zhangsan@example.com',
      phone: '13800138000',
      gender: '男',
      status: '在职',
      entry_date: Time.now,
      created_at: Time.now,
      updated_at: Time.now
    }
    
    employee_id = Common::M.insert_one('org_employees', employee_data).inserted_id
    
    # 验证员工是否创建成功
    employee = Common::M.find_one('org_employees', { _id: employee_id })
    assert_equal '张三', employee['name']
    assert_equal 'EMP001', employee['employee_id']
    
    puts "测试成功：创建了组织、部门、职位和员工"
    puts "组织ID: #{org_id}"
    puts "部门ID: #{dept_id}"
    puts "职位ID: #{position_id}"
    puts "员工ID: #{employee_id}"
  end
end
