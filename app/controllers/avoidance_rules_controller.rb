class AvoidanceRulesController < ApplicationController
  before_action :set_avoidance_rule, only: %i[edit update destroy]

  def index
    @avoidance_rules = Current.user.avoidance_rules.order(active: :desc, created_at: :asc)
  end

  def new
    @avoidance_rule = Current.user.avoidance_rules.new
  end

  def create
    @avoidance_rule = Current.user.avoidance_rules.new(avoidance_rule_params)

    if @avoidance_rule.save
      redirect_to avoidance_rules_path, notice: "やらないことを登録しました。"
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit; end

  def update
    if @avoidance_rule.update(avoidance_rule_params)
      redirect_to avoidance_rules_path, notice: "やらないことを更新しました。"
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @avoidance_rule.destroy!
    redirect_to avoidance_rules_path,
                notice: "やらないことを削除しました。過去の着手記録は残っています。",
                status: :see_other
  end

  private

  def set_avoidance_rule
    @avoidance_rule = Current.user.avoidance_rules.find(params[:id])
  end

  def avoidance_rule_params
    params.require(:avoidance_rule).permit(:title, :active)
  end
end
