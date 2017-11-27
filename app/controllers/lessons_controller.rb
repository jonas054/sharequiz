require 'csv'
require 'pythonic_privates'

class LessonsController < ApplicationController
  extend PythonicPrivates

  helper :application
  before_filter(:authorize,
                :except => [:index, :show, :add_filter, :remove_filter])

  # GET /lessons?[lang1=X][&lang2=Y][&created_by=Z][&title_match=W]
  def index
    if session[:user_id]
      user = User.find session[:user_id]
      @statistics = Statistic.refresh_for(user).sort_by { |s|
        Language.find(s.language_id).own_name
      }
    else
      @statistics = []
    end
    _filter_lessons
    @page_title = _page_title text(:home) + " (#{@page || 1})"
  end

  # GET /lessons/history
  def history
    user        = User.find(session[:user_id])
    @history    = Statistic.history user
    @goal       = user.goal
    @page_title = _page_title text(:history)
  end

  # GET /lessons/new
  def new
    @lesson     = Lesson.new
    @languages  = Language.all_for_select
    @page_title = _page_title text(:new_lesson)
  end

  # GET /lessons/edit/1
  def edit
    @lesson = Lesson.find params[:id]
    if @lesson.user.id != session[:user_id]
      redirect_to :action => "index"
      return
    end
    @query_to_edit = params[:query_id] ? Query.find(params[:query_id]) : nil
    @new_query     = Query.new
    @duplicates, @orig_queries = Query.duplicates_of @lesson
    @languages     = Language.all_for_select
    @page_title    = _page_title '"' + @lesson.name + '"'
  end

  # GET /lessons/show/1
  def show
    @lesson     = Lesson.find params[:id]
    @page_title = _page_title '"' + @lesson.name + '"'
  end

  # POST /lessons
  def create
    @languages = Language.all_for_select
    params[:lesson][:user] = User.find session[:user_id]
    @lesson = Lesson.create params[:lesson]
    if @lesson.save
      redirect_to :action => "edit", :id => @lesson.id
    else
      render :action => "new"
    end
  end

  # GET /lessons/add_filter/1
  def add_filter
    session[:filter] ||= {}
    (params[:filter] || {}).each { |k,v|
      session[:filter][k.to_sym] = v # convert string keys to symbol keys
    }
    # :title_match comes in params, not params[:filter]
    session[:filter][:title_match] ||= params[:title_match]
    redirect_to :action => "index"
  end

  # GET /lessons/remove_filter/1
  def remove_filter
    params[:filter].each { |f|
      if f == 'lang1' and session[:filter][:lang2]
        session[:filter][:lang1] = session[:filter][:lang2]
        session[:filter].delete :lang2
      else
        session[:filter].delete f.to_sym
      end
    }
    redirect_to :action => "index"
  end

  # GET /lessons/run
  def run
    _choose_query
    session[:questions_left] = User.find(session[:user_id]).quiz_length
    session[:progress] = []
    @page_title = _page_title @query.effective_question
  end

  # GET /lessons/answer/1
  def answer
    # If there's something wrong with the incoming data, redirect.
    [[session[:user_id], 'index'],
     [params[:query],    'run']].each { |data, place|
      redirect_to :action => place and return unless data
    }
    q    = Query.find params[:id]
    know = q.knowledge session[:user_id]
    know.nr_of_answers += 1
    reply = params[:query][session[:reversed] ? :question : :answer]
    reply.force_encoding 'utf-8' if reply.respond_to? :force_encoding
    if q.answer_ok? reply, session[:reversed], params[:answer_index]
      know.nr_of_correct_answers += 1
      know.time_for_last_correct_answer = Time.now
      session[:questions_left] -= 1
      session[:progress] << true
    else
      @correct_answer = if session[:reversed] then q.question else q.answer end
      @last_question  = if session[:reversed] then q.answer else q.question end
      @last_lesson    = q.lesson
      @wrong_answer   = reply
      @clue           = q.clue
      session[:progress] << false
    end
    know.save!
    if session[:questions_left] <= 0
      end_quiz
    else
      _choose_query q
      @page_title = _page_title @query.effective_question
      render :action => "run"
    end
  end

  def _page_title(s)
    s + ' - ShareQuiz'
  end

  def _choose_query(q = nil)
    _filter_lessons
    @query, @answer_index = Query.choose(@selected_lessons,
                                         session[:user_id], session[:reversed],
                                         q)
  end

  def _filter_lessons
    session[:filter] ||= {}
    @lang1, @lang2 = [:lang1, :lang2].map { |lg|
      Language.find session[:filter][lg] if session[:filter][lg]
    }
    @title_match = session[:filter][:title_match]
    options = { :conditions => _sql_conditions }
    @selected_lessons = Lesson.find :all, options
    @sort             = params[:sort]
    @page             = options[:page] = params[:page]
    options[:order] = case @sort
                      when /name/     then 'name'
                      when /language/ then 'question_lang_id'
                      when /creator/  then 'users.name'
                      when nil        then 'created_at DESC'
                      end + "#{' DESC' if @sort =~ /^_/}"
    options[:joins] = :user if @sort =~ /creator/
    @page_lessons = Lesson.paginate options.merge(:per_page => 20)
  end

  def _sql_conditions
    cond, data = [], []
    if @title_match
      # Escape the string to allow special characters in it.
      escaped_title = @title_match.gsub('%', '\%').gsub('_', '\_')
      # Avoid SQL injection vulnerability by using question mark.
      cond, data = ["name LIKE ?"], ["%#{escaped_title}%"]
    end
    if session[:filter][:created_by]
      @created_by = User.find_by_name session[:filter][:created_by]
      cond << "user_id = #{@created_by.id}"
    else
      @created_by = nil
    end
    cond += [@lang1, @lang2].compact.map { |lang|
      "(question_lang_id = #{lang.id} OR answer_lang_id = #{lang.id})"
    }
    [cond.join(" AND ")] + data
  end

  # GET /lessons/end_quiz
  def end_quiz
    session[:reversed] = !session[:reversed]
    redirect_to :action => "index"
  end

  # PUT /lessons/1
  def update
    case params[:commit]
    when text(:save_lesson)
      @lesson = Lesson.find params[:id]
      if @lesson.update_attributes params[:lesson]
        redirect_to :action => "index"
      else
        render :action => "edit"
      end
      return

    when text(:add)
      q = Query.new params[:new_query]
      q.lesson_id = params[:id]

    when text(:save)
      q = Query.find params[:query_id]
      if q.update_attributes params[:query_to_edit]
        # Knowledge not relevant anymore since query has changed.
        Knowledge.delete_all "query_id = #{q.id}"
      end
    end
    q.save_with_new_knowledge session[:user_id]
    redirect_to :action => "edit", :id => params[:id]
  end

  # DELETE /lessons/1
  def destroy
    lesson = Lesson.find params[:id]
    lesson.queries.each { |query| query.destroy }
    lesson.destroy
    redirect_to :action => "index"
  end

  # GET /lessons/1
  def import
    @lesson = Lesson.find params[:id]
    if params[:csv]
      # We allow tabs instead of commas in the CSV text to make it easier to
      # copy tables from a word processor or spreadsheet.
      CSV.parse(params[:csv][:text].gsub(/\t/,',').gsub(/"/,'')) { |question, answer, clue|
        q = Query.new({ :lesson    => @lesson,
                        :question  => question.to_s,
                        :answer    => answer.to_s,
                        :clue      => clue.to_s})
        q.save_with_new_knowledge session[:user_id]
      }
      redirect_to :action => "edit", :id => @lesson.id
    end
  rescue Exception => e
    flash[:error] = e.to_s
  end

  # GET /lessons/transpose_qa
  def transpose_qa
    _transpose { |q| q.question, q.answer = q.answer, q.question }
  end

  # GET /lessons/transpose_ac
  def transpose_ac
    _transpose { |q| q.clue, q.answer = q.answer, q.clue }
  end

  def _transpose
    @lesson = Lesson.find params[:id]
    @lesson.queries.each { |q|
      yield q
      q.save!
    }
    redirect_to :action => "edit", :id => @lesson.id
  end
end
