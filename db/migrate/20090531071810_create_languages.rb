# -*- coding: utf-8 -*-
class CreateLanguages < ActiveRecord::Migration
  def self.up
    create_table :languages do |t|
      t.column :own_name,     :string
      t.column :english_name, :string

      t.timestamps
    end
  end

  def self.down
    drop_table :languages
  end
end
