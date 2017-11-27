class CreateStatistics < ActiveRecord::Migration
  def self.up
    create_table :statistics do |t|
      t.integer :user_id
      t.integer :language_id
      t.integer :wordcount

      t.timestamps
    end

    # Since knowledge of the user's native language isn't interesting, and
    # shouldn't be presented, we need to know which language is native.
    add_column(:users, :native_language, :integer,
               :default => Language.find_by_english_name('English').id)
  end

  def self.down
    drop_table :statistics
  end
end
