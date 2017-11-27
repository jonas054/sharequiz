class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.string :name
      t.string :description
      t.string :hashed_password
      t.string :salt
      t.string :display_language, :default => 'English'
      t.integer :quiz_length, :default => 10
      
      t.timestamps
    end
    User.create(:name => 'admin',
                :description => 'The administrator of the ShareQuiz system.',
                :password => 'xena77wp',  :password_confirmation => 'xena77wp')
  end

  def self.down
    drop_table :users
  end
end
