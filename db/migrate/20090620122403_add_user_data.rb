class AddUserData < ActiveRecord::Migration
  def self.up
    User.create :name => 'jonas', :password => 'utcstr', :password_confirmation => 'utcstr'
    User.create :name => 'bob', :password => 'bob', :password_confirmation => 'bob'
    User.create :name => 'wanghong', :password => 'wanghong', :password_confirmation => 'wanghong'
  end

  def self.down
    User.find_by_name('wanghong').delete
    User.find_by_name('bob').delete
    User.find_by_name('jonas').delete
  end
end
