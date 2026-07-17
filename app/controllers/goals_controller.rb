class GoalsController < ApplicationController
  before_action :set_goal, only: %i[show edit update destroy]

  def index
    @goals = Current.user.goals.order(target_date: :asc, created_at: :asc)
  end

  def show
    @tasks = @goal.tasks.order(scheduled_date: :asc, created_at: :asc)
  end

  def new
    @goal = Current.user.goals.new
  end

  def create
    @goal = Current.user.goals.new(goal_params)

    if @goal.save
      redirect_to @goal, notice: "目標を作成しました。"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @goal.update(goal_params)
      redirect_to @goal, notice: "目標を更新しました。"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @goal.destroy!
    redirect_to goals_path, notice: "目標を削除しました。関連するタスクは残っています。", status: :see_other
  end

  private

  def set_goal
    @goal = Current.user.goals.find(params[:id])
  end

  def goal_params
    params.require(:goal).permit(:title, :desired_future, :avoided_future, :target_date)
  end
end
