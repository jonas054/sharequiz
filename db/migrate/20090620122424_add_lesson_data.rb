# -*- coding: utf-8 -*-
class AddLessonData < ActiveRecord::Migration
  def self.up
    bob, jonas, wanghong = %w"bob jonas wanghong".map { |name| User.find_by_name(name).id }
    f, e, s, c = %w"French English Swedish Chinese".map { |name|
      Language.find_by_english_name(name).id
    }
    
    create_lesson bob, f, s, 'Greetings'
    create_lesson bob, f, e, 'Paris'
    create_lesson bob, s, c, 'Test'
    create_lesson wanghong, e, c, 'lesson1'
    create_lesson jonas, c, s, 'CPod A1: Enkla hälsningsfraser'
    create_lesson jonas, c, s, 'CPod A2: Varifrån kommer du?'
    create_lesson jonas, c, s, 'CPod A3: Vart ska du gå?'
    create_lesson jonas, c, s, 'CPod A4: Hur mår du?'
    create_lesson jonas, c, s, 'CPod A5: Mer känslor med förklaringar'
    create_lesson jonas, c, s, 'CPod A6: Kan du tala kinesiska?'
    create_lesson jonas, c, s, 'CPod A7: Kan du sjunga?'
    create_lesson jonas, c, s, 'CPod A8: Herr Li'
    create_lesson jonas, c, s, 'CPod A9: Att handla'
    create_lesson jonas, c, s, 'CPod A11: Att äta ute'
    create_lesson jonas, c, s, 'CPod A12: Att beskriva mat'
    create_lesson jonas, c, s, 'CPod A13: Fröken Li tycker om att dricka'
    create_lesson jonas, c, s, 'CPod A15: Att fira helger'
    create_lesson jonas, c, s, 'CPod A16: Dagar och månader'
    create_lesson jonas, c, s, 'CPod A17: Inledande kundmöten'
    create_lesson jonas, c, s, 'CPod A18: Mobiltelefoner'
    create_lesson jonas, c, s, 'CPod A19: Färger'
    create_lesson jonas, c, s, 'CPod A20: Shopping'
    create_lesson jonas, c, s, 'CPod A21: Personlig information'
    create_lesson jonas, c, s, 'CPod A22: Artiga presentationer'
    create_lesson jonas, c, s, 'CPod A23: Ring mig!'
    create_lesson jonas, c, s, 'CPod A24: Vart är du på väg?'
    create_lesson jonas, c, s, 'CPod A25: Sevärdheter'
    create_lesson jonas, c, s, 'CPod A26: Vem är hon?'
    create_lesson jonas, c, s, 'CPod A27: I familjen'
    create_lesson jonas, c, s, 'CPod A28: Tid för möte'
    create_lesson jonas, c, s, 'CPod A29: 9 till 5'
    create_lesson jonas, c, s, 'CPod A30: Ansiktet'
    create_lesson jonas, c, s, 'CPod A31: Toner del 2'
    create_lesson jonas, c, s, 'CPod A32: Jag känner dig'
    create_lesson jonas, c, s, 'CPod A33: Jag måste gå'
    create_lesson jonas, c, s, 'CPod A34: Familjeband'
    create_lesson jonas, c, s, 'CPod A36: Yrkesliv'
    create_lesson jonas, c, s, 'CPod B51: Nationaliteter'
    create_lesson jonas, c, s, 'CPod B50: Doggybag'
    create_lesson jonas, c, s, 'CPod B49: Så pinsamt!'
    create_lesson jonas, c, s, 'CPod B48: Husdjur'
    create_lesson jonas, c, s, 'CPod B47: Solskydd'
    create_lesson jonas, c, s, 'CPod B46: Att få en dejt'
    create_lesson jonas, c, s, 'CPod B45: Att gå till kyrkan'
    create_lesson jonas, c, s, 'CPod B44: Att ladda ett kontantkort'
  end

  def self.down
  end

  private

  def self.create_lesson(user, question_lang, answer_lang, name)
    Lesson.create(:name => name, :user_id => user,
                  :question_lang_id => question_lang,
                  :answer_lang_id => answer_lang)
  end
end
