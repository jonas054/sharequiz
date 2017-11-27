class Statistic < ActiveRecord::Base
  extend TimeAgo

  attr_accessor :is_on_track
  
  belongs_to :user
  belongs_to :language

  validates_presence_of     :user_id, :language_id, :wordcount
  validates_numericality_of :wordcount, :greater_than_or_equal_to => 0

  # Calculates new statistics for all languages, saves the ones that
  # are changed compared to the database, and returns the newest
  # statistics in an array. One element per language.
  def self.refresh_for(user)
    latest =
      Language.find(:all,
                    :conditions => "id != #{user.native_language}").map {|lang|
      Knowledge.statistic_for user.id, lang.id
    }
    latest.reject! { |s| s.wordcount == 0 }
    newest_in_db = {}
    find_all_for(user).each { |s| newest_in_db[s.language_id] ||= s }
    latest.each { |s|
      n = newest_in_db[s.language_id]
      if n.nil? or s.wordcount != n.wordcount
        s.save!
        newest_in_db[s.language_id] = s
      end
    }
    newest_in_db.values
  end

  SECONDS_PER_DAY = 60 * 60 * 24
  
  # Returns an array of arrays of historical statistics for the given
  # user. Each sub array is for one language. E.g.: [[stat4, stat1], [stat3, 
  # stat2]]. The top level elements are sorted with the one containing the
  # newest statistic (stat4) first. The statistic arrays are also sorted with
  # the newest first (stat4 before stat1, stat3 before stat2).
  def self.history(user)
    refresh_for user
    hist = find_all_for(user).group_by { |s| s.language_id }
    sorted = hist.values.sort_by { |stats|
      stats.map { |s| s.created_at.to_i }.max
    }
    sorted.each { |lang_array|
      newest = lang_array.first
      lang_array[1..-1].each { |s|
        new_words_learnt = newest.wordcount - s.wordcount
        if new_words_learnt >= goal_words_learnt(newest, s, user)
          s.is_on_track = newest.is_on_track = true
        end
      }
    }
    sorted.reverse
  end

  def self.goal_words_learnt(newest, other, user)
    seconds_passed = newest.created_at.to_i - other.created_at.to_i
    days_passed    = seconds_passed.to_f / SECONDS_PER_DAY
    user.goal * days_passed / 7
  end
  
  # Purges user's statistics and then returns all statistics for the
  # given user, newest first. E.g., if there are two statistics that
  # will be labeled "2 hours ago" on the history page, we remove one
  # of them.
  def self.find_all_for(user)
    found = find_all_by_user_id(user.id,
                                :conditions =>
                                "language_id != #{user.native_language}",
                                :order => 'created_at DESC')
    by_lang     = found.group_by { |s| s.language_id }
    maxes       = by_lang.map { |k, v| [k, v.map { |s| s.wordcount }.max] }
    high_scores = Hash[*maxes.flatten]

    by_lang.values.each { |lang_group|
      time_span = Time.now - lang_group.last.created_at
      
      # 1. If the user obviously hasn't practised the language for a while and
      #    is at less than 10% of his/her goal, remove old values to enable a
      #    fresh start.
      while lang_group.any? and
          lang_group.first.wordcount <
          0.10 * (lang_group.last.wordcount + user.goal * time_span/60/60/24/7)
        lang_group.last.delete
        found.delete lang_group.last
        lang_group.delete_at -1
      end

      # 2. Remove data points that don't change the shape of the curve much.
      #    Start at 1 instead of 0 in order to never delete the second newest.
      (1..lang_group.size-3).each { |i|
        z,y,x = lang_group[i, 3] # put x,y,z in time order - easier
        # We can delete y if it's on the line between x and z.
        #
        # wordcount
        # ^                    z       -
        # |                            |
        # |            y               w
        # |                            |
        # | x                          -
        # +--------------------------> created_at
        #   |--- t0 ---|
        #   |------- t --------|
        t = z.created_at - x.created_at
        if t < time_span/10 and t > time_span/100
          # We put a limit on how big time intervals we meddle in. This ensures
          # that we don't delete too much and leave the user with a straight
          # line across the chart.
          t0 = y.created_at - x.created_at
          w  = z.wordcount - x.wordcount
          if (x.wordcount+(t0*w/t).round-y.wordcount).abs < y.wordcount/150 and
              y.wordcount < high_scores[y.language_id] # never delete highscore
            found.delete y # in return value
            y.delete # in database
          end
        end
      }
    }

    # 3. Remove data points that are within the same time group as an
    #    older data point.
    found.group_by { |s| [timeago(s.created_at),
                          s.language_id] }.values.each do |list|
      next if list.size < 2
      # The list contains statistics that have the same language and
      # were updated roughly at the same time. In each time group, we
      # delete all data points except one. The one we keep is either
      # the oldest or one whose wordcount is a high score for the user
      # in that language.
      list = list.sort_by { |s|
        # The overall newest statistic and high score are preserved.
        # If the newest statistic and the high score are in the same
        # group, it's the high score that's preserved.
        [(s.id        == found.first.id ||
          s.wordcount == high_scores[s.language_id]) ? 0 : 1,
         s.created_at]
      }
      list[1..-1].each { |s|
        found.delete s # in return value
        s.delete # in database
      }
    end
    found
  end
end
