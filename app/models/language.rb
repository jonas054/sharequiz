# -*- coding: utf-8 -*-
class Language < ActiveRecord::Base
  validates_presence_of :own_name, :english_name
  validates_uniqueness_of :own_name, :english_name  
  
  def self.all_for_select
    all = Language.find(:all).map { |lang| [lang.own_name, lang.id] }
    all.sort_by { |own_name, id| own_name } 
  end
end
