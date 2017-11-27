require 'test_helper'

class StatisticTest < ActiveSupport::TestCase
  HIGH_SCORE = 1000

  def setup
    @jonas = users(:jonas)
    create_some_data @jonas.id, :chi
  end

  def create_some_data(user_id, lang_key)
    {
      (Time.now-5.weeks)  => 7,  # oldest in time group
      (Time.now-34.days)  => 8,  # just highest in group, WILL BE REMOVED

      (Time.now-15.days)  => 88,   # oldest in time group, but WILL BE REMOVED
      (Time.now-14.days)  => HIGH_SCORE,
      (Time.now-14.days)  => 99,   # WILL BE REMOVED

      (Time.now-50.hours) => 900,  # oldest in time group, but WILL BE REMOVED
      (Time.now-49.hours) => HIGH_SCORE,

      (Time.now-48.minutes) => 900, # second newest
      (Time.now-47.minutes) => 900  # the newest
    }.each { |time, wc|
      create_stat user_id, lang_key, time, wc
    }
  end

  def create_stat(user_id, lang_key, time, wc)
    s = Statistic.create(:user_id     => user_id,
                         :language_id => languages(lang_key).id,
                         :wordcount   => wc)
    s.created_at = time
    s.save!
  end
  private :create_stat
  
  # Tests that statistics that were created roughly at the same time
  # are cleaned up so that only the oldest remains. The highest
  # score a user has in each language is not removed.
  def test_find_all_for
    create_some_data @jonas.id, :eng

    all = Statistic.find :all
    result = Statistic.find_all_for @jonas

    # Three new statistics should remain. One created 14 days ago
    # should be removed, since it's labelled "2 weeks" old, just like
    # two others. Another one from 14 days ago is kept since it
    # represents the user's high score.

    remaining = Statistic.find(:all,
                               :conditions => { :user_id => @jonas.id },
                               :order      => 'created_at')
    per_language = remaining.group_by { |s| s.language_id }
    assert_equal result.sort_by { |s| s.id }, remaining.sort_by { |s| s.id }
    assert_equal 10, remaining.size, present(per_language)
    per_language.each { |lang_id, stats|
      expected_remaining = [5.weeks, 14.days, 49.hours, 48.minutes, 47.minutes]
      expected_remaining.each_with_index { |passed_time, ix|
        diff = Integer(Time.now - passed_time - stats[ix].created_at).abs
        assert(diff < 10, "at index #{ix} for language #{lang_id}: #{diff}")
      }
      # The high score shall have been preserved.
      assert_equal HIGH_SCORE, stats[-3].wordcount
    }
  end

  def present(per_language)
    per_language.map { |lang,arr| [lang, arr.map { |s| s.wordcount }] }.inspect
  end
  
  def test_refresh
    Knowledge.create!(:nr_of_answers                => 10,
                      :nr_of_correct_answers        => 8,
                      :time_for_last_correct_answer => Time.now - 1.week,
                      :query_id                     => queries(:maison_hus).id,
                      :user_id                      => @jonas.id)
    stats =
      Statistic.refresh_for(@jonas).sort_by { |s| s.language.english_name }

    assert_equal [languages(:chi),
                  languages(:fre)], stats.map { |s| s.language }
    assert_equal [900, 1], stats.map { |s| s.wordcount }
  end

  def test_history
    Statistic.create!(:user_id     => @jonas.id,
                      :language_id => languages(:swe).id,
                      :wordcount   => 2000)
    hist = Statistic.history @jonas

    assert_equal languages(:chi).id, hist[0][0].language_id
    assert_equal([900, 900, HIGH_SCORE, HIGH_SCORE, 7],
                 hist[0].map { |s| s.wordcount })
  end
end
