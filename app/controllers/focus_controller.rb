class FocusController < ApplicationController
  before_action :set_focus_session, only: %i[extend complete interrupt]

  def show
    @selected_task = Current.user.tasks.find(params[:task_id]) if params[:task_id].present?
    @active_session = Current.user.work_sessions.open.focus_timers.includes(task: :goal).first
    @tasks = Current.user.tasks.includes(:goal).where(status: %w[pending active]).order(scheduled_date: :asc, created_at: :asc)
  end

  def start
    task = Current.user.tasks.find(params.require(:task_id))
    task.start!(planned_duration_seconds: WorkSession::FOCUS_DURATION_SECONDS)

    redirect_to focus_path, notice: "5分タイマーを開始しました。"
  rescue ActiveRecord::RecordInvalid => error
    redirect_to focus_path(task_id: task&.id), alert: error.record.errors.full_messages.to_sentence
  end

  def extend
    seconds = params.require(:seconds).to_i
    @focus_session.extend_by!(seconds)

    redirect_to focus_path, notice: "タイマーを#{seconds / 60}分延長しました。"
  rescue ArgumentError
    redirect_to focus_path, alert: "延長時間が不正です。"
  end

  def complete
    goal = @focus_session.task.goal
    @focus_session.task.complete!

    redirect_to focus_path, notice: completion_message(goal)
  end

  def interrupt
    goal = @focus_session.task.goal
    @focus_session.task.interrupt!

    redirect_to focus_path, notice: interruption_message(goal)
  end

  private

  def set_focus_session
    @focus_session = Current.user.work_sessions.open.focus_timers.find(params[:work_session_id])
  end

  def completion_message(goal)
    return "タスクを完了しました。おつかれさまでした。" unless goal

    "未来への一歩を記録しました。目標：#{goal.title}。近づきたい未来：#{goal.desired_future}。" \
      "今週、この目標に向けて着手した回数：#{goal.starts_this_week_count}回。"
  end

  def interruption_message(goal)
    return "作業を中断しました。" unless goal

    "着手した事実は記録されています。目標：#{goal.title}。" \
      "今週、この目標に向けて着手した回数：#{goal.starts_this_week_count}回。"
  end
end
