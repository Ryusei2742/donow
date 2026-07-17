class TasksController < ApplicationController
  before_action :set_task, only: %i[show edit update destroy start complete interrupt skip]
  before_action :set_goals, only: %i[new create edit update]

  def index
    @tasks = Current.user.tasks.order(scheduled_date: :asc, created_at: :asc)
  end

  def show
    @work_sessions = @task.work_sessions.recent_first
  end

  def new
    @task = Current.user.tasks.new
  end

  def create
    @task = Current.user.tasks.new(task_params)

    if @task.save
      redirect_to @task, notice: "タスクを作成しました。"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @task.update(task_params)
      redirect_to @task, notice: "タスクを更新しました。"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @task.destroy!
    redirect_to tasks_path, notice: "タスクを削除しました。", status: :see_other
  end

  def start
    @task.start!
    redirect_back fallback_location: @task, notice: "着手を記録しました。まず5分だけ進めましょう。"
  rescue ActiveRecord::RecordInvalid => error
    redirect_back fallback_location: @task, alert: error.record.errors.full_messages.to_sentence
  end

  def complete
    @task.complete!
    redirect_back fallback_location: @task, notice: "タスクを完了しました。"
  end

  def interrupt
    @task.interrupt!
    redirect_back fallback_location: @task, notice: "作業を中断しました。"
  end

  def skip
    @task.skip!
    redirect_back fallback_location: @task, notice: "タスクをスキップしました。"
  end

  private

  def set_task
    @task = Current.user.tasks.find(params[:id])
  end

  def task_params
    permitted = params.require(:task).permit(
      :title,
      :description,
      :status,
      :scheduled_date,
      :estimated_minutes,
      :goal_id
    )
    goal_id = permitted.delete(:goal_id)
    permitted[:goal_id] = goal_id.present? ? Current.user.goals.find(goal_id).id : nil
    permitted
  end

  def set_goals
    @goals = Current.user.goals.order(:title)
  end
end
