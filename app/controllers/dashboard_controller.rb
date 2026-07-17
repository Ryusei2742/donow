class DashboardController < ApplicationController
  def index
    @tasks = Current.user.tasks.scheduled_for(Date.current).order(:status, :created_at)
    @completed_count = @tasks.completed.count
    @incomplete_count = @tasks.where.not(status: :completed).count
    @started_count = @tasks.joins(:work_sessions).distinct.count
    @goals = Current.user.goals.order(target_date: :asc, created_at: :asc)
  end
end
