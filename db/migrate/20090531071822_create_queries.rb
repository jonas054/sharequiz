class CreateQueries < ActiveRecord::Migration
  def self.up
    create_table :queries do |t|
      t.string :question
      t.string :answer
      t.string :clue

      t.belongs_to :lesson

      t.timestamps
    end
  end

  def self.down
    drop_table :queries
  end
end
