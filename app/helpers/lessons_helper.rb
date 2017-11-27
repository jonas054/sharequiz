# -*- coding: utf-8 -*-
require 'cedict'
require 'cgi'

module LessonsHelper
  include TimeAgo

  # Methods for building HTML strings. First argument to these methods is an
  # optional hash of attributes. Subsequent arguments, if any, are contents
  # strings that will be joined. Examples:
  # _td('HEJ')                     => <td>HEJ</td>
  # _div({:class => 'inner'}, _br) => <div class="inner"><br /></div>
  %w'table tr td div span b'.each { |m|
    define_method('_' + m) { |*args|
      if Hash === args.first
        attr = args.shift.map { |k,v| %' #{k}="#{v}"' }.sort.join
      end
      "<#{m}#{attr}" + if args.empty?
                         ' />'
                       else
                         ">#{args.join}</#{m}>"
                       end
    }
  }

  def remove_filter(which_filter)
    link_to(image_tag('16x16_button_cancel.png', :border => '0',
                      :title => text(:remove_this_filter)),
            :action => 'remove_filter',
            :params => { :filter => [which_filter] })
  end
  
  def possibly_chinese_td(language, field)
    _td(language.english_name =~ /Chinese/ ? { :class => 'chinese' } : {},
        Query.top_level_split(field).map{ |f|
          colorize f, language.id
        }.join('<br/>'))
  end

  def colorize(phrase, language_id)
    return phrase unless has_chinese(language_id)
    tones = CeDict.tones(phrase)
    if tones != [0]
      phrase.chars.zip(tones).map { |c, t|
        %Q'<span class="tone#{t}">#{c}</span>'
      }.join
    else
      phrase
    end
  end
  
  def query_fields(query, button_text)
    '' +
      _td(text_field(query, :question, :size => 20)) +
      _td(text_field(query, :answer,   :size => 20)) +
      _td(text_field(query, :clue,     :size => 20)) +
      _td(submit_tag(text(button_text)))
  end

  def buttons_for_show(lesson)
    link_with_image('16x16_kjobviewer.png',
                    { :controller => 'lessons',
                      :action     => 'show',
                      :id         => lesson.id },
                    :title => text(:show))
  end
  
  def buttons_for_edit_and_remove(query)
    unless @query_to_edit
      url = {
        :controller => 'queries',
        :id         => query.id,
        :lesson_id  => @lesson.id }
      '' +
        link_with_image('16x16_button_cancel.png',
                        url.merge(:action => 'destroy'),
                        :confirm => ("#{text :remove} #{query.question} /" +
                                     " #{query.answer}?"),
                        :method  => :delete,
                        :title   => text(:remove)) +
        ' ' +
        link_with_image('16x16_color_line.png', url.merge(:action => 'edit'),
                        :title => text(:edit))
    end
  end

  def button_row_for_index
    if session[:user_id]
      user = User.find session[:user_id]
      '' +
        if @page_lessons.blank?
          ''
        else
          render_button('1rightarrow', text(:start_quiz), 'lessons/run/1',
                        text(:for_the_listed_lessons))
        end +
        render_button('package_edutainment', text(:add_a_lesson),
                      'lessons/new') +

        render_button('kcontrol', text(:tools), 'login/preferences') +

        render_button('kchart', text(:history), 'lessons/history') +

        render_button('exit', text(:log_out) + " #{_b(user.name)}",
                      "login/logout/#{user.id}", text(:close_the_session),
                      :post)
    else
      render_button('edit_user', text(:log_in), 'login/login',
                    text(:to_be_able_to_run_quizzes_and_create_lessons))
    end +
      render_button('help', text(:help), 'login/help')
  end

  def button_row_for_edit
    '' +
      button_to(text(:remove, :lesson).capitalize,
                { :action => 'destroy', :id => @lesson.id },
                :confirm => "#{text(:remove).capitalize} #{@lesson.name} ?",
                :method  => :delete) +
      render_button('kjobviewer', text(:show), "lessons/show/#{@lesson.id}") +

      render_button('kaboodleloop',
                    "#{text(:transpose, :questions)}/#{text(:answers)}",
                    "lessons/transpose_qa/#{@lesson.id}", :post) +

      render_button('kaboodleloop',
                    "#{text(:transpose, :answers)}/#{text(:clues)}",
                    "lessons/transpose_ac/#{@lesson.id}", :post) +

      render_button('download_manager', text(:import, :questions),
                    "lessons/import/#{@lesson.id}")
  end

  def button_row_for_run
    render_button('keyboard', text(:type, :chinese, :characters), '', '', nil,
                  { :href  => ('http://www.mdbg.net/chindict/'+
                               'webime2.php?ime=mand_simp'),
                    :popup => ['height=480,width=450'] })
  end

  def render_button(image, txt, url_string, tooltip = '', method = nil,
                    html_opt = {})
    controller, action, id = url_string.split %r'/'
    url = [controller, action, id].any? ? {
      :controller => controller,
      :action     => action,
      :id         => id
    } : {}
    _div(link_to(image_tag("32x32_#{image}.png", :border => 0, :title => '') +
                 raw(_span(txt)),
                 url,
                 {
                   :class  => 'functions',
                   :title  => tooltip,
                   :method => method
                 }.merge(html_opt)))
  end

  def lesson_link_if_owner(lesson)
    if lesson.user.id == session[:user_id]
      link_to(lesson.name,
              { :controller => 'lessons',
                :action     => 'edit',
                :id         => lesson.id },
              :class => 'functions',
              :title => text(:edit_lesson))
    else
      lesson.name
    end
  end

  def class_for_language(*ids)
    if has_chinese(*ids)
      'class="chinese"'
    else
      ''
    end
  end

  def has_chinese(*ids)
    ids.detect { |id| Language.find(id).english_name =~ /Chinese/i }
  end

  def has_spanish(*ids)
    ids.detect { |id| Language.find(id).english_name =~ /Spanish/i }
  end

  def progress_bar
    _table({ :class => 'progress' },
           _tr(session[:progress].map { |b| progress_square(b ? 'green' :
                                                            'red') }.join +
               progress_square('white') * session[:questions_left]))
  end

  def progress_square(color)
    _td :bgcolor => color, :height => 10, :width => 10
  end

  def history_graph(xcoord, ycoord)
    xmax      = xcoord.max # seconds passed, oldest to now
    xcoord    = xcoord.map { |x| 997*(xmax-x)/1000 } # make oldest x = 0
    table     = [xcoord, ycoord].transpose.sort_by { |x,y| x }
    y_at_0    = table[0][1]
    y_goal    = y_at_0 + goal_delta(xmax)
    y_scale   = [y_goal, ycoord.max*11/10].max
    dot_color = '3300FF'
    # ycoord.each_with_index.map only works in ruby => 1.8.7.
    dots = [ycoord, (0...ycoord.size).to_a].transpose.map { |y, ix|
      if y == ycoord.max
        # a larger dot with a white center
        "o,#{dot_color},0,#{ix},8,1|o,FFFFFF,0,#{ix},4,1"
      elsif y >= y_at_0 + goal_delta(xcoord[ix])
        "o,#{dot_color},0,#{ix},6,1" # dots for points above green line
      end
    }.compact.join '|'
    coordinates = "#{xcoord.join ','}|#{ycoord.join ','}" +
      "|0,#{xmax}|#{y_at_0},#{y_goal}"
    line_colors = '000000,00A000' # black and green
    line_style  = '2,1,0|1,3,3' # thickness, segment length, space
    x_at_newest, y_at_newest = table[-1]
    if y_at_newest >= y_goal
      y_projected_at_0 = y_at_newest - goal_delta(x_at_newest)
      if y_projected_at_0 >= 0
        coordinates += "|0,#{x_at_newest}|#{y_projected_at_0},#{y_at_newest}"
        line_colors += ',A0A000' # yellow
        line_style  += '|1,3,3'
      end
    end
    time_percent = (100 / (xmax.to_f / timechunk(xmax))).round
    #               x step, y step, length, space, x offset, y offset:
    grid         = "#{time_percent},0,2,5,#{100 % time_percent},0"
    '<img class="chart" src="http://chart.apis.google.com/chart' + "\?" + {
      :chco => line_colors,
      :chd  => 't:' + coordinates,            # data
      :chds => "0,#{xmax},0,#{y_scale}",      # data scaling
      :chg  => grid,
      :chls => line_style,
      :chm  => "#{horizontal_lines(y_scale)}|#{dots}", # markers
      :chma => '0,30,5,15',                   # margins
      :chs  => '600x500',                     # size of chart area
      :cht  => 'lxy',                         # chart type = X/Y line
      :chxr => "0,0,#{y_scale}",              # axis range
      :chxt => 'r'                            # axis type = right
    }.map {|k,v| "#{k}=#{v}"}.sort.join('&') +
      '" />'
  end

  def horizontal_lines(y_scale)
    # Calculate a suitable distance (a number starting with 1, 2, or 5,
    # that will give between 1 and 10 help lines along the y axis).
    line_dist = 1
    while y_scale/line_dist > 10
      line_dist = if line_dist.to_s =~ /^[15]/
                    line_dist * 2
                  else # begins with 2
                    line_dist / 2 * 5
                  end
    end
    (1..y_scale/line_dist).map { |y|
      "h,B00000,0,#{sprintf '%.3f', y.to_f*line_dist/y_scale},0.5,1"
    }.join '|'
  end
  
  def goal_delta(x) @goal * x / 60 / 60 / 24 / 7 end

  def language_form(prompt)
    select('filter', @lang1 ? 'lang2' : 'lang1', Language.all_for_select,
           {:prompt => prompt}, {:onchange => 'langform.submit()'})
  end

  def heading_with_sorting(title, property)
    link_to(text(title),
            { :sort => "#{'_' if @sort == property}#{property}" },
            :title => text(:change_sorting_order))
  end

  def dictionary_links(q_lang_id, a_lang_id, question, answer)
    word = if has_chinese q_lang_id
             question
           elsif has_chinese a_lang_id
             answer
           end
    if word
      dictionary_link('nciku', word) + ' ' + dictionary_link('MDBG', word)
    else
      ''
    end
  end

  def dictionary_link(provider, word)
    word.split(/\s*[#{Query::SemiColon}]\s*/).map { |w|
      link_to(image_tag("#{provider.downcase}-favicon.PNG", :border => '0',
                        :title => "#{provider} Chinese-English Dictionary"),
              send("#{provider.downcase}_url",
                   w.gsub(/[#{Query::AnyPar}]/, '')))
    }.join(' ')
  end

  def mdbg_url(word)
    page = CeDict.is_in_mdbg_word_dictionary(word) ? 'wdqchid' : 'wdqchs'
    "http://www.mdbg.net/chindict/chindict.php?#{page}=#{CGI::escape(word)}"
  end

  def nciku_url(word)
    "http://www.nciku.com/search/all/#{CGI::escape(word)}"
  end

  def lesson_score(lesson)
    if session[:user_id]
      score_td lesson.score(session[:user_id]), 'right'
    else
      ''
    end
  end

  def query_score(q)
    k = q.knowledge session[:user_id]
    score_td k ? k.score : 0, 'center'
  end

  def score_td(s, alignment)
    color = case Knowledge.score_group s
            when :none     then '#ffffff' # white
            when :negative then '#ffbbbb' # red
            when :partial  then '#ffff88' # yellow
            when :full     then '#bbffbb' # green
            end
    # TODO - use CSS classes for coloring and alignment
    _td({ :bgcolor => color, :align => alignment }, s.to_s)
  end
end
