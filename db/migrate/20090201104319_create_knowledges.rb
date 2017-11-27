class CreateKnowledges < ActiveRecord::Migration
  def self.up
    create_table :knowledges do |t|
      t.integer :nr_of_answers, :default => 0
      t.integer :nr_of_correct_answers, :default => 0
      t.datetime :time_for_last_correct_answer

      t.belongs_to :user
      t.belongs_to :query

      t.timestamps
    end
  end

  def self.down
    drop_table :knowledges
  end
end
