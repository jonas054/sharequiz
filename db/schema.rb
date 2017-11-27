# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20120104134124) do

  create_table "knowledges", :force => true do |t|
    t.integer  "nr_of_answers",                :default => 0
    t.integer  "nr_of_correct_answers",        :default => 0
    t.datetime "time_for_last_correct_answer"
    t.integer  "user_id"
    t.integer  "query_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "languages", :force => true do |t|
    t.string   "own_name"
    t.string   "english_name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "lessons", :force => true do |t|
    t.string   "name"
    t.integer  "question_lang_id",                    :null => false
    t.integer  "answer_lang_id",                      :null => false
    t.boolean  "is_private",       :default => false
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "queries", :force => true do |t|
    t.string   "question"
    t.string   "answer"
    t.string   "clue"
    t.integer  "lesson_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "statistics", :force => true do |t|
    t.integer  "user_id"
    t.integer  "language_id"
    t.integer  "wordcount"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", :force => true do |t|
    t.string   "name"
    t.string   "description"
    t.string   "hashed_password"
    t.string   "salt"
    t.string   "display_language", :default => "English"
    t.integer  "quiz_length",      :default => 10
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "native_language",  :default => 2
    t.integer  "goal",             :default => 10,        :null => false
  end

end
