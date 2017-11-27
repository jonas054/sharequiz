module HistoryHelper
  def tds(statistic, ymax)
    is_bold = statistic.wordcount == ymax
    td(statistic.wordcount.to_s,      is_bold, statistic.is_on_track) +
    td(timeago(statistic.created_at), is_bold, statistic.is_on_track)
  end
  
  def td(s, is_bold, is_on_track)
    s = "<b>#{s}</b>" if is_bold
    cls = is_on_track ? 'class="goal"' : ''
    '<td align="right" ' + cls + '>' + s + '</td>'
  end
end

