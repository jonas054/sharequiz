class AddGoalToUser < ActiveRecord::Migration
  def self.up
    # I first tried with just :default => 10 but that didn't seem to
    # work on heroku, which uses PostgreSQL. On MySQL it
    # worked. Adding :null => false seems to have solved the problem.
    add_column :users, :goal, :int, :default => 10, :null => false
  end

  def self.down
    remove_column :users, :goal
  end
end
