class HistoryController < ApplicationController
  def index
    @tasks_by_date = Current.user.tasks.includes(:work_sessions)
      .where(scheduled_date: ..Date.current)
      .recent_first
      .group_by(&:scheduled_date)
    @work_sessions = Current.user.work_sessions.includes(:task).recent_first.limit(50)
  end
end
