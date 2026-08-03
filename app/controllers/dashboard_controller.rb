class DashboardController < ApplicationController
  def index
    load_dashboard
  end

  def quick_start
    @quick_task = Current.user.tasks.new(quick_start_params)
    @quick_task.scheduled_date = Date.current

    Current.user.with_lock do
      active_session = Current.user.work_sessions.open.first
      return restore_or_reject(active_session) if active_session

      Task.transaction do
        @quick_task.save!
        @quick_task.start!(
          planned_duration_seconds: WorkSession::FOCUS_DURATION_SECONDS,
          avoidance_rule: selected_avoidance_rule
        )
      end
    end

    redirect_to focus_path, notice: "「#{@quick_task.title}」の5分タイマーを開始しました。"
  rescue ActiveRecord::RecordInvalid
    load_dashboard
    render :index, status: :unprocessable_content
  end

  private

  def load_dashboard
    @quick_task ||= Current.user.tasks.new
    @tasks = Current.user.tasks.includes(:goal, :work_sessions)
                         .scheduled_for(Date.current)
                         .order(:status, :created_at)
    @completed_count = @tasks.completed.count
    @incomplete_count = @tasks.where.not(status: :completed).count
    @started_count = @tasks.joins(:work_sessions).distinct.count
    @goals = Current.user.goals.order(target_date: :asc, created_at: :asc)
    @resume_task = resume_task
  end

  def resume_task
    incomplete_tasks = Current.user.tasks.where(status: %i[pending active])
    last_started = incomplete_tasks.joins(:work_sessions)
                                   .order("work_sessions.started_at DESC")
                                   .first

    last_started || incomplete_tasks.order(updated_at: :desc).first
  end

  def quick_start_params
    params.require(:task).permit(:title)
  end

  def selected_avoidance_rule
    return if params[:avoidance_rule_id].blank?

    Current.user.avoidance_rules.active.find_by(id: params[:avoidance_rule_id])
  end

  def restore_or_reject(active_session)
    if active_session.focus_timer?
      redirect_to focus_path, notice: "進行中の5分タイマーを表示しました。"
    else
      redirect_to root_path, alert: "別のタスクが進行中です。完了または中断してから始めてください。"
    end
  end
end
