# -*- coding: utf-8 -*-
require 'test_helper'

include TimeAgo

class LibTest < ActiveSupport::TestCase
  test "timeago" do
    check_english_and_swedish(10,
                              [[" 10 seconds", " 10 sekunder"],
                               [" 50 seconds", " 50 sekunder"],
                               ["  4 minutes", "  4 minuter"],
                               [" 21 minutes", " 21 minuter"],
                               ["104 minutes", "104 minuter"],
                               ["  9 hours",   "  9 timmar"],
                               ["  2 days",    "  2 dagar"],
                               ["  9 days",    "  9 dagar"],
                               ["  6 weeks",   "  6 veckor"],
                               ["  8 months",  "  8 månader"],
                               ["  3 years",   "  3 år"]]) { |seconds|
      seconds * 5
    }
    check_english_and_swedish(0, [["0 seconds", "0 sekunder"],
                                  ["1 second",  "1 sekund"],
                                  ["2 seconds", "2 sekunder"]]) { |seconds|
      seconds + 1
    }
  end

  test "timechunk" do
    seconds = 10
    [1, 1, 60, 60, 60, 3600, 86400, 86400, 604800, 2592000,
     31557600, 31557600, 31557600, 31557600, 31557600, 31557600].each { |exp|
      assert_equal exp, timechunk(seconds)
      seconds *= 5
    }
  end

  def session
      { :display_language => @language }
  end
  
  def check_english_and_swedish(start, exp_array)
    seconds = start
    exp_array.each { |exp|
      @language = 'English'
      assert_equal exp[0].strip, timeago(Time.now-seconds)
      @language = 'Swedish'
      assert_equal exp[1].strip, timeago(Time.now-seconds)
      seconds = yield seconds
    }
  end

  test "cedict" do
    assert CeDict.is_in_mdbg_word_dictionary("一下")
    assert !CeDict.is_in_mdbg_word_dictionary("下一")

    assert CeDict.is_in_mdbg_word_dictionary("ｎ遍")
    assert CeDict.is_in_mdbg_word_dictionary("〇")
  end

  test "cedict single character tone" do
    assert_equal [3], CeDict.tones('我')
  end

  test "cedict word and expression tones" do
    assert_equal [1, 4],       CeDict.tones("一下")
    assert_equal [3, 2, 4],    CeDict.tones('美容院')
    assert_equal [3, 5],       CeDict.tones('本子')
    assert_equal [2, 5, 2, 4], CeDict.tones('玩儿游戏')
    assert_equal [1, 0, 3, 3], CeDict.tones('一把雨伞')
    assert_equal [1, 5],       CeDict.tones('哥哥')
    assert_equal([4, 3, 2],    CeDict.tones('瑞典文'))
  end

  test "cedict words with duplicate entries" do
    assert_equal [3],    CeDict.tones('海')
    assert_equal [4],    CeDict.tones('蚌')
    assert_equal [3, 4], CeDict.tones('海蚌')
  end

  test "cedict alternative expression tones" do
    # There is an entry 上个星期4411 in the dictionary, which is why
    # we get the 4th tone for 个 before 星期, but 5th (neutral) before
    # 礼拜.
    #             上 (  个  )  星 期     =    上  (  个 )  礼  拜
    assert_equal([4, 0, 4, 0, 1, 1, 0, 0, 0, 4, 0, 5, 0, 3, 4],
                 CeDict.tones('上(个)星期 = 上(个)礼拜'))
    assert_equal([4, 3, 3, 0, 0, 0, 4, 3, 2],
                 CeDict.tones('瑞典语 = 瑞典文'))
  end

  test "cedict sentence tones" do
    ['。', '？', '！'].each { |ending|
      assert_equal [1, 5, 0], CeDict.tones('哥哥' + ending)
    }
  end

  test "cedict parenthesized expression tones" do
    assert_equal [1, 0, 5, 0],          CeDict.tones('哥(哥)')
    assert_equal [1, 0, 5, 0],          CeDict.tones('哥（哥）')
    assert_equal [3, 0, 1, 0, 5, 0, 0], CeDict.tones('我(哥(哥))')
    assert_equal [1, 0, 5, 0],          CeDict.tones('哥（哥）')
  end

  test "should not be too slow" do
    real = nil
    2.times { # 1st run is warm-up
      real = Benchmark.realtime {
        assert CeDict.is_in_mdbg_word_dictionary("一下")
      }
    }
    assert real < 0.001, "took #{real}s"
  end
end
