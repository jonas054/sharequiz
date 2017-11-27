require 'pythonic_privates'

class QueriesController < ApplicationController
  extend PythonicPrivates

  # GET /queries/1/edit
  def edit
    _find
    _redirect_to_lessons_edit :query_id => params[:id]
  end

  # DELETE /queries/1
  def destroy
    _find
    @query.destroy
    _redirect_to_lessons_edit
  end

  def _redirect_to_lessons_edit(more_params = {})
    std = {
      :controller => "lessons",
      :action     => "edit",
      :id         => params[:lesson_id]
    }
    redirect_to std.merge(more_params)
  end

  def _find() @query = Query.find params[:id] end
end
