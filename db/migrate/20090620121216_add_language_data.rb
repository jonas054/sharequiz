# -*- coding: utf-8 -*-
class AddLanguageData < ActiveRecord::Migration
  def self.up
    [
     ["Dansk",      "Danish"],
     ["Deutsch",    "German"],
     ["English",    "English"],
     ["Español",    "Spanish"],
     ["Français",   "French"],
     ["Italiano",   "Italian"],
     ["Nederlands", "Dutch"],
     ["Norsk",      "Norwegian"],
     ["Polski",     "Polish"],
     ["Português",  "Portugese"],
     ["Русский",    "Russian"],
     ["Suomi",      "Finnish"],
     ["Svenska",    "Swedish"],
     ["日本語",      "Japanese"],
     ["中文",        "Chinese"]
    ].each { |own, eng|
      Language.create :own_name => own, :english_name => eng
    }
  end

  def self.down
  end
end
