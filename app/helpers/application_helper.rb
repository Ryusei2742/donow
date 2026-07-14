module ApplicationHelper
  TASK_STATUS_LABELS = {
    "pending" => "未完了",
    "active" => "着手中",
    "completed" => "完了",
    "skipped" => "スキップ"
  }.freeze

  SESSION_STATUS_LABELS = {
    "active" => "作業中",
    "completed" => "完了",
    "interrupted" => "中断"
  }.freeze

  def task_status_label(task)
    TASK_STATUS_LABELS.fetch(task.status, task.status)
  end

  def session_status_label(session)
    SESSION_STATUS_LABELS.fetch(session.status, session.status)
  end

  def format_date(date)
    date == Date.current ? "今日（#{date.strftime('%-m/%-d')}）" : date.strftime("%Y年%-m月%-d日")
  end

  def format_time(time)
    time&.in_time_zone&.strftime("%-m/%-d %H:%M")
  end
end
