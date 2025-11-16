class TaheController < ApiController
  before do
    content_type :json
    # authenticate_user!
  end

  # 首页
  get '/org/index' do
    kr :'org_structure/layui_index'
  end

  # 使用标签库系统的组织结构页面
  get '/org/layui_index' do
    content_type :html
    kr :'org_structure/layui_index'
  end

  # 获取组织列表
  get '/org/list' do
    orgs = Common::M['c_orgs'].query({ status: true }, { sort: { sort_order: 1 } }).to_a
    org_tree = build_org_tree(orgs)
    { status: 'success', data: org_tree }.to_json
  end

  # 获取组织详情 - 注意这个路由必须放在具体路由之后
  get '/org/:id' do
    begin
      org_id = BSON::ObjectId(params[:id])
      org = Common::M['c_orgs'].query({ _id: org_id }).first
      halt 404, { status: 'error', message: '组织不存在' }.to_json unless org
      { status: 'success', data: org }.to_json
    rescue => e
      # 更通用的错误处理
      halt 400, { status: 'error', message: "无效的ID格式: #{e.message}" }.to_json
    end
  end

  # 创建组织
  post '/org/create' do
    begin
      params = JSON.parse(request.body.read)
      
      # 准备组织数据
      org_data = params.dup
      org_data['created_at'] = Time.now
      org_data['updated_at'] = Time.now
      
      # 设置组织路径和层级
      if params['parent_id'] && !params['parent_id'].empty?
        begin
          parent_id = BSON::ObjectId(params['parent_id'])
          parent = Common::M['c_orgs'].query({ _id: parent_id }).first
          halt 400, { status: 'error', message: '上级组织不存在' }.to_json unless parent
          
          # 插入组织并获取ID
          result = Common::M['c_orgs'].add(org_data)
          org_id = result.inserted_id
          
          # 更新路径和层级
          path = parent['path'] + org_id.to_s + '/'
          level = (parent['level'] || 1) + 1
          
          Common::M['c_orgs'].update({ _id: org_id }, { '$set': { path: path, level: level } })
          
          # 获取更新后的组织数据
          org = Common::M['c_orgs'].query({ _id: org_id }).first
          { status: 'success', data: org }.to_json
        rescue BSON::ObjectId::Invalid
          halt 400, { status: 'error', message: '无效的上级组织ID格式' }.to_json
        end
      else
        # 插入组织并获取ID
        result = Common::M['c_orgs'].add(org_data)
        org_id = result.inserted_id
        
        # 更新路径和层级
        path = '/' + org_id.to_s + '/'
        level = 1
        
        Common::M['c_orgs'].update({ _id: org_id }, { '$set': { path: path, level: level } })
        
        # 获取更新后的组织数据
        org = Common::M['c_orgs'].query({ _id: org_id }).first
        { status: 'success', data: org }.to_json
      end
    rescue => e
      halt 400, { status: 'error', message: '创建组织失败', error: e.message }.to_json
    end
  end

  # 更新组织
  put '/org/:id' do
    begin
      org_id = BSON::ObjectId(params[:id])
      org = Common::M['c_orgs'].query({ _id: org_id }).first
      halt 404, { status: 'error', message: '组织不存在' }.to_json unless org
      
      update_params = JSON.parse(request.body.read)
      update_params.delete('path') # 不允许直接修改路径
      update_params.delete('level') # 不允许直接修改层级
      
      # 如果修改了上级组织，需要更新路径和层级
      if update_params['parent_id'] && update_params['parent_id'] != org['parent_id']
        begin
          parent_id = BSON::ObjectId(update_params['parent_id'])
          parent = Common::M['c_orgs'].query({ _id: parent_id }).first
          halt 400, { status: 'error', message: '上级组织不存在' }.to_json unless parent
          
          # 检查是否形成循环依赖
          halt 400, { status: 'error', message: '不能选择自己或子组织作为上级组织' }.to_json if parent['path'].include?(org_id.to_s)
          
          # 设置新的路径和层级
          new_path = parent['path'] + org_id.to_s + '/'
          new_level = (parent['level'] || 1) + 1
          
          update_params['path'] = new_path
          update_params['level'] = new_level
          
          # 更新所有子组织的路径和层级
          update_children_path_and_level(org)
        rescue BSON::ObjectId::Invalid
          halt 400, { status: 'error', message: '无效的上级组织ID格式' }.to_json
        end
      end
      
      update_params['updated_at'] = Time.now
      
      # 更新组织
      result = Common::M['c_orgs'].update({ _id: org_id }, { '$set': update_params })
      
      if result.modified_count > 0
        updated_org = Common::M['c_orgs'].query({ _id: org_id }).first
        { status: 'success', data: updated_org }.to_json
      else
        halt 400, { status: 'error', message: '更新组织失败' }.to_json
      end
    rescue BSON::ObjectId::Invalid
      halt 400, { status: 'error', message: '无效的组织ID格式' }.to_json
    rescue => e
      halt 400, { status: 'error', message: '更新组织失败', error: e.message }.to_json
    end
  end

  # 删除组织
  delete '/org/:id' do
    begin
      org_id = BSON::ObjectId(params[:id])
      org = Common::M['c_orgs'].query({ _id: org_id }).first
      halt 404, { status: 'error', message: '组织不存在' }.to_json unless org
      
      # 检查是否有子组织
      children = Common::M['c_orgs'].query({ parent_id: org_id.to_s }).count
      halt 400, { status: 'error', message: '该组织下有子组织，无法删除' }.to_json if children > 0
      
      # 检查是否有部门
      departments = Common::M['org_departments'].query({ org_id: org_id.to_s }).count
      halt 400, { status: 'error', message: '该组织下有部门，无法删除' }.to_json if departments > 0
      
      # 检查是否有员工
      employees = Common::M['org_employees'].query({ org_id: org_id.to_s }).count
      halt 400, { status: 'error', message: '该组织下有员工，无法删除' }.to_json if employees > 0
      
      # 删除组织
      result = Common::M['c_orgs'].del({ _id: org_id })
      
      if result.deleted_count > 0
        { status: 'success', message: '删除组织成功' }.to_json
      else
        halt 400, { status: 'error', message: '删除组织失败' }.to_json
      end
    rescue BSON::ObjectId::Invalid
      halt 400, { status: 'error', message: '无效的组织ID格式' }.to_json
    rescue => e
      halt 400, { status: 'error', message: '删除组织失败', error: e.message }.to_json
    end
  end

  # 获取组织下的部门列表
  get '/org/:id/departments' do
    begin
      org_id = BSON::ObjectId(params[:id])
      
      # 检查组织是否存在
      org = Common::M['c_orgs'].query({ _id: org_id }).first
      halt 404, { status: 'error', message: '组织不存在' }.to_json unless org
      
      # 获取部门列表
      departments = Common::M['org_departments'].query({ org_id: org_id.to_s, status: true }, { sort: { sort_order: 1 } }).to_a
      
      # 返回数据
      { status: 'success', data: departments }.to_json
    rescue BSON::ObjectId::Invalid
      halt 400, { status: 'error', message: '无效的组织ID格式' }.to_json
    rescue => e
      halt 500, { status: 'error', message: '获取部门列表失败', error: e.message }.to_json
    end
  end
  
  # 获取组织下的职位列表
  get '/org/:id/positions' do
    begin
      org_id = BSON::ObjectId(params[:id])
      
      # 检查组织是否存在
      org = Common::M['c_orgs'].query({ _id: org_id }).first
      halt 404, { status: 'error', message: '组织不存在' }.to_json unless org
      
      # 获取职位列表
      positions = Common::M['org_positions'].query({ org_id: org_id.to_s, status: true }, { sort: { level: -1, sort_order: 1 } }).to_a
      
      # 返回数据
      { status: 'success', data: positions }.to_json
    rescue BSON::ObjectId::Invalid
      halt 400, { status: 'error', message: '无效的组织ID格式' }.to_json
    rescue => e
      halt 500, { status: 'error', message: '获取职位列表失败', error: e.message }.to_json
    end
  end
  
  # 获取组织下的员工列表
  get '/org/:id/employees' do
    begin
      org_id = BSON::ObjectId(params[:id])
      
      # 检查组织是否存在
      org = Common::M['c_orgs'].query({ _id: org_id }).first
      halt 404, { status: 'error', message: '组织不存在' }.to_json unless org
      
      # 获取员工列表
      employees = Common::M['org_employees'].query({ org_id: org_id.to_s }).to_a
      
      # 对员工数据进行处理，添加部门和职位名称
      employees.each do |employee|
        if employee['department_id']
          begin
            dept_id = BSON::ObjectId(employee['department_id'])
            department = Common::M['org_departments'].query({ _id: dept_id }).first
            employee['department_name'] = department ? department['name'] : nil
          rescue
            employee['department_name'] = nil
          end
        end
        
        if employee['position_id']
          begin
            pos_id = BSON::ObjectId(employee['position_id'])
            position = Common::M['org_positions'].query({ _id: pos_id }).first
            employee['position_name'] = position ? position['name'] : nil
          rescue
            employee['position_name'] = nil
          end
        end
      end
      
      # 返回数据
      { status: 'success', data: employees }.to_json
    rescue BSON::ObjectId::Invalid
      halt 400, { status: 'error', message: '无效的组织ID格式' }.to_json
    rescue => e
      halt 500, { status: 'error', message: '获取员工列表失败', error: e.message }.to_json
    end
  end

  # 获取部门列表
  get '/api/department/list' do
    org_id = params[:org_id]
    departments = MOrgDepartment.where(org_id: org_id, status: true).order(sort_order: 1).to_a
    department_tree = build_department_tree(departments)
    { status: 'success', data: department_tree }.to_json
  end

  # 获取部门详情
  get '/api/department/:id' do
    department = MOrgDepartment.find(params[:id])
    halt 404, { status: 'error', message: '部门不存在' }.to_json unless department
    { status: 'success', data: department }.to_json
  end

  # 创建部门
  post '/api/department/create' do
    params = JSON.parse(request.body.read)
    department = MOrgDepartment.new(params)
    
    # 设置部门路径和层级
    if params['parent_id']
      parent = MOrgDepartment.find(params['parent_id'])
      halt 400, { status: 'error', message: '上级部门不存在' }.to_json unless parent
      department.path = parent.path + department.id.to_s + '/'
      department.level = parent.level + 1
    else
      department.path = '/' + department.id.to_s + '/'
      department.level = 1
    end
    
    department.created_at = Time.now
    department.updated_at = Time.now
    
    if department.save
      { status: 'success', data: department }.to_json
    else
      halt 400, { status: 'error', message: '创建部门失败', errors: department.errors }.to_json
    end
  end

  # 更新部门
  put '/api/department/:id' do
    department = MOrgDepartment.find(params[:id])
    halt 404, { status: 'error', message: '部门不存在' }.to_json unless department
    
    params = JSON.parse(request.body.read)
    params.delete('path') # 不允许直接修改路径
    params.delete('level') # 不允许直接修改层级
    
    # 如果修改了上级部门，需要更新路径和层级
    if params['parent_id'] && params['parent_id'] != department.parent_id
      parent = MOrgDepartment.find(params['parent_id'])
      halt 400, { status: 'error', message: '上级部门不存在' }.to_json unless parent
      
      # 检查是否形成循环依赖
      halt 400, { status: 'error', message: '不能选择自己或子部门作为上级部门' }.to_json if parent.path.include?(department.id.to_s)
      
      department.path = parent.path + department.id.to_s + '/'
      department.level = parent.level + 1
      
      # 更新所有子部门的路径和层级
      update_children_department_path_and_level(department)
    end
    
    params['updated_at'] = Time.now
    
    if department.update(params)
      { status: 'success', data: department }.to_json
    else
      halt 400, { status: 'error', message: '更新部门失败', errors: department.errors }.to_json
    end
  end

  # 删除部门
  delete '/api/department/:id' do
    department = MOrgDepartment.find(params[:id])
    halt 404, { status: 'error', message: '部门不存在' }.to_json unless department
    
    # 检查是否有子部门
    children = MOrgDepartment.where(parent_id: department.id).count
    halt 400, { status: 'error', message: '该部门下有子部门，无法删除' }.to_json if children > 0
    
    # 检查是否有员工
    employees = MOrgEmployee.where(department_id: department.id).count
    halt 400, { status: 'error', message: '该部门下有员工，无法删除' }.to_json if employees > 0
    
    if department.destroy
      { status: 'success', message: '删除部门成功' }.to_json
    else
      halt 400, { status: 'error', message: '删除部门失败' }.to_json
    end
  end

  # 获取职位列表
  get '/api/position/list' do
    org_id = params[:org_id]
    positions = MOrgPosition.where(org_id: org_id, status: true).order(level: -1, sort_order: 1).to_a
    { status: 'success', data: positions }.to_json
  end

  # 获取职位详情
  get '/api/position/:id' do
    position = MOrgPosition.find(params[:id])
    halt 404, { status: 'error', message: '职位不存在' }.to_json unless position
    { status: 'success', data: position }.to_json
  end

  # 创建职位
  post '/api/position/create' do
    params = JSON.parse(request.body.read)
    position = MOrgPosition.new(params)
    position.created_at = Time.now
    position.updated_at = Time.now
    
    if position.save
      { status: 'success', data: position }.to_json
    else
      halt 400, { status: 'error', message: '创建职位失败', errors: position.errors }.to_json
    end
  end

  # 更新职位
  put '/api/position/:id' do
    position = MOrgPosition.find(params[:id])
    halt 404, { status: 'error', message: '职位不存在' }.to_json unless position
    
    params = JSON.parse(request.body.read)
    params['updated_at'] = Time.now
    
    if position.update(params)
      { status: 'success', data: position }.to_json
    else
      halt 400, { status: 'error', message: '更新职位失败', errors: position.errors }.to_json
    end
  end

  # 删除职位
  delete '/api/position/:id' do
    position = MOrgPosition.find(params[:id])
    halt 404, { status: 'error', message: '职位不存在' }.to_json unless position
    
    # 检查是否有员工使用该职位
    employees = MOrgEmployee.where(position_id: position.id).count
    halt 400, { status: 'error', message: '有员工使用该职位，无法删除' }.to_json if employees > 0
    
    if position.destroy
      { status: 'success', message: '删除职位成功' }.to_json
    else
      halt 400, { status: 'error', message: '删除职位失败' }.to_json
    end
  end

  # 获取员工列表
  get '/api/employee/list' do
    org_id = params[:org_id]
    department_id = params[:department_id]
    
    query = { org_id: org_id }
    query[:department_id] = department_id if department_id
    
    employees = MOrgEmployee.where(query).to_a
    { status: 'success', data: employees }.to_json
  end

  # 获取员工详情
  get '/api/employee/:id' do
    employee = MOrgEmployee.find(params[:id])
    halt 404, { status: 'error', message: '员工不存在' }.to_json unless employee
    { status: 'success', data: employee }.to_json
  end

  # 创建员工
  post '/api/employee/create' do
    params = JSON.parse(request.body.read)
    employee = MOrgEmployee.new(params)
    employee.created_at = Time.now
    employee.updated_at = Time.now
    
    if employee.save
      { status: 'success', data: employee }.to_json
    else
      halt 400, { status: 'error', message: '创建员工失败', errors: employee.errors }.to_json
    end
  end

  # 更新员工
  put '/api/employee/:id' do
    employee = MOrgEmployee.find(params[:id])
    halt 404, { status: 'error', message: '员工不存在' }.to_json unless employee
    
    params = JSON.parse(request.body.read)
    params['updated_at'] = Time.now
    
    if employee.update(params)
      { status: 'success', data: employee }.to_json
    else
      halt 400, { status: 'error', message: '更新员工失败', errors: employee.errors }.to_json
    end
  end

  # 删除员工
  delete '/api/employee/:id' do
    employee = MOrgEmployee.find(params[:id])
    halt 404, { status: 'error', message: '员工不存在' }.to_json unless employee
    
    if employee.destroy
      { status: 'success', message: '删除员工成功' }.to_json
    else
      halt 400, { status: 'error', message: '删除员工失败' }.to_json
    end
  end

  private

  # 构建组织树
  def build_org_tree(orgs, parent_id = nil)
    tree = []
    orgs.select { |org| org['parent_id'].to_s == parent_id.to_s }.each do |org|
      children = build_org_tree(orgs, org['_id'])
      org_data = org
      org_data['children'] = children unless children.empty?
      tree << org_data
    end
    tree
  end

  # 构建部门树
  def build_department_tree(departments, parent_id = nil)
    tree = []
    departments.select { |dept| dept.parent_id == parent_id }.each do |dept|
      children = build_department_tree(departments, dept.id)
      dept_data = dept.to_h
      dept_data[:children] = children unless children.empty?
      tree << dept_data
    end
    tree
  end

  # 更新子组织的路径和层级
  def update_children_path_and_level(org)
    begin
      org_id = org['_id'].is_a?(BSON::ObjectId) ? org['_id'] : BSON::ObjectId(org['_id'])
      children = Common::M['c_orgs'].query({ parent_id: org_id.to_s }).to_a
      
      children.each do |child|
        child_id = child['_id']
        new_path = org['path'] + child_id.to_s + '/'
        new_level = org['level'] + 1
        
        # 更新子组织的路径和层级
        Common::M['c_orgs'].update({ _id: child_id }, { '$set': { path: new_path, level: new_level } })
        
        # 递归更新子组织的子组织
        updated_child = Common::M['c_orgs'].query({ _id: child_id }).first
        update_children_path_and_level(updated_child)
      end
    rescue => e
      puts "Error updating children: #{e.message}"
    end
  end

  # 更新子部门的路径和层级
  def update_children_department_path_and_level(department)
    children = MOrgDepartment.where(parent_id: department.id).to_a
    children.each do |child|
      child.path = department.path + child.id.to_s + '/'
      child.level = department.level + 1
      child.save
      update_children_department_path_and_level(child)
    end
  end
end
