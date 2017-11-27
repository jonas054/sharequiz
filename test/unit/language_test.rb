# -*- coding: utf-8 -*-
require 'test_helper'

class LanguageTest < ActiveSupport::TestCase
  test 'blank names' do
    check_save_errors(Language.new, ["Own name can't be blank",
                                     "English name can't be blank"])
    check_save_errors(Language.new(:own_name => 'Norsk'),
                      ["English name can't be blank"])
    check_save_errors(Language.new(:english_name => 'Norwegian'),
                      ["Own name can't be blank"])
  end
  
  test 'duplicate names' do
    names = { :own_name => 'Norsk', :english_name => 'Norwegian' }
    Language.create!(names)
    check_save_errors(Language.new(names),
                      ['Own name has already been taken',
                       'English name has already been taken'])
    check_save_errors(Language.new(:own_name => 'Bokmål',
                                   :english_name => 'Norwegian'),
                      ['English name has already been taken'])
    check_save_errors(Language.new(:own_name => 'Svenska',
                                   :english_name => 'Scandinavian'),
                      ['Own name has already been taken'])
  end
end
