class FocusController < ApplicationController
  def show
    @task = Current.user.tasks.find(params[:task_id]) if params[:task_id].present?
  end
end
