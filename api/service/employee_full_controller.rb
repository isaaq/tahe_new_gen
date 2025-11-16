require 'sinatra/base'

class EmployeeFullController < Sinatra::Base
  set :views, File.join(File.dirname(__FILE__), '..', 'views')
  
  get '/full' do
    erb :employee_management_full
  end
  
  get '/full/employees' do
    erb :employee_management_full
  end
end

