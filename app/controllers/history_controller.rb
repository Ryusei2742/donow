class HistoryController < ApplicationController
  def index
    @tasks_by_date = Task.includes(:work_sessions)
      .where(scheduled_date: ..Date.current)
      .recent_first
      .group_by(&:scheduled_date)
    @work_sessions = WorkSession.includes(:task).recent_first.limit(50)
  end
end
