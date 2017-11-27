class ChangeGoalFromDailyToWeekly < ActiveRecord::Migration
  def self.up
    User.find(:all).each { |user|
      user.goal = 7 * user.goal
      user.save!
    }
  end

  def self.down
    User.find(:all).each { |user|
      user.goal = (user.goal + 3) / 7
      user.save!
    }
  end
end
