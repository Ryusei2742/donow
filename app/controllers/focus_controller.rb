class FocusController < ApplicationController
  def show
    @task = Task.find_by(id: params[:task_id])
  end
end
