module TimeAgo
  include Translation

  # Returns a string describing how much time has passed since the
  # given 'datetime'. With the exception of "1 second", the algorithm
  # makes it easy for itself by ensuring that the number is at least
  # 2, so that the unit is always in plural. The unit is translated
  # according to the chosen session display language.
  def timeago(datetime)
    sec = (Time.now - datetime).round
    return "(+#{-sec})" if sec < 0

    # Special handling for "0 seconds" (which the generic algorithm
    # can't handle) and "1 second" (which must be singular).
    return "#{sec} " + text("second#{'s' if sec==0}".to_sym) if sec <= 1

    unit = find_unit sec
    (sec.to_f / 1.send(unit)).round.to_s + " " + text(unit)
  end

  # Returns an amount of seconds that is equal to one year, one month,
  # one week, or some such value. The value is smaller than 'sec'
  # divided by the threshold value.
  def timechunk(sec)
    fail "sec = #{sec}" if sec < 1
    1.send(find_unit(sec)).round
  end

  private

  def find_unit(sec)
    [:years, :months, :weeks, :days, :hours, :minutes, :seconds].find { |u|
      1.send(u) <= sec/1.8
    }
  end
end
