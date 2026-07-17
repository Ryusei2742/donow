class FocusController < ApplicationController
  before_action :set_focus_session, only: %i[extend complete interrupt]

  def show
    @selected_task = Current.user.tasks.find(params[:task_id]) if params[:task_id].present?
    @active_session = Current.user.work_sessions.open.focus_timers.includes(:task).first
    @tasks = Current.user.tasks.where(status: %w[pending active]).order(scheduled_date: :asc, created_at: :asc)
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
    @focus_session.task.complete!
    redirect_to focus_path, notice: "タスクを完了しました。おつかれさまでした。"
  end

  def interrupt
    @focus_session.task.interrupt!
    redirect_to focus_path, notice: "作業を中断しました。"
  end

  private

  def set_focus_session
    @focus_session = Current.user.work_sessions.open.focus_timers.find(params[:work_session_id])
  end
end
