class CreateLessons < ActiveRecord::Migration
  def self.up
    create_table :lessons do |t|
      t.string :name
      t.integer :question_lang_id, :answer_lang_id, :null => false
      t.boolean :is_private, :default => false

      t.belongs_to :user

      t.timestamps
    end
  end

  def self.down
    drop_table :lessons
  end
end
