require "rails_helper"

RSpec.describe "Goals", type: :request do
  let(:password) { "password123" }
  let(:user) { User.create!(email_address: "owner@example.com", password: password) }
  let(:valid_attributes) do
    {
      title: "Webエンジニアとして就職する",
      desired_future: "技術を使って働く選択肢が増える未来に近づく",
      avoided_future: "応募に進めない状態が続く可能性がある",
      target_date: Date.current + 3.months
    }
  end

  before do
    post session_path, params: { email_address: user.email_address, password: password }
  end

  it "creates, reads, updates, and deletes an owned goal" do
    expect do
      post goals_path, params: { goal: valid_attributes }
    end.to change(user.goals, :count).by(1)

    goal = user.goals.last
    expect(response).to redirect_to(goal_path(goal))

    get goal_path(goal)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(goal.title, goal.desired_future, goal.avoided_future)

    patch goal_path(goal), params: { goal: { title: "更新した目標" } }
    expect(response).to redirect_to(goal_path(goal))
    expect(goal.reload.title).to eq("更新した目標")

    expect { delete goal_path(goal) }.to change(user.goals, :count).by(-1)
    expect(response).to redirect_to(goals_path)
  end

  it "shows only the signed-in user's goals in the index and task form" do
    own_goal = user.goals.create!(valid_attributes)
    other_user = User.create!(email_address: "other@example.com", password: password)
    other_goal = other_user.goals.create!(valid_attributes.merge(title: "他人の目標"))

    get goals_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(own_goal.title)
    expect(response.body).not_to include(other_goal.title)

    get new_task_path
    expect(response.body).to include(own_goal.title)
    expect(response.body).not_to include(other_goal.title)
  end

  it "requires login for every goal action" do
    goal = user.goals.create!(valid_attributes)
    delete session_path

    requests = [
      -> { get goals_path },
      -> { get new_goal_path },
      -> { post goals_path, params: { goal: valid_attributes } },
      -> { get goal_path(goal) },
      -> { get edit_goal_path(goal) },
      -> { patch goal_path(goal), params: { goal: { title: "変更不可" } } },
      -> { delete goal_path(goal) }
    ]

    requests.each do |request|
      request.call
      expect(response).to redirect_to(new_session_path)
    end

    expect(goal.reload.title).to eq(valid_attributes[:title])
  end

  it "cannot access another user's goal through any member action" do
    other_user = User.create!(email_address: "other@example.com", password: password)
    other_goal = other_user.goals.create!(valid_attributes.merge(title: "変更できない目標"))

    requests = [
      -> { get goal_path(other_goal) },
      -> { get edit_goal_path(other_goal) },
      -> { patch goal_path(other_goal), params: { goal: { title: "不正更新" } } },
      -> { delete goal_path(other_goal) }
    ]

    requests.each do |request|
      request.call
      expect(response).to have_http_status(:not_found)
    end

    expect(other_goal.reload.title).to eq("変更できない目標")
  end

  describe "task association" do
    it "associates a task with the signed-in user's goal" do
      goal = user.goals.create!(valid_attributes)

      post tasks_path, params: { task: task_attributes.merge(goal_id: goal.id) }

      expect(response).to redirect_to(task_path(user.tasks.last))
      expect(user.tasks.last.goal).to eq(goal)
    end

    it "does not associate a task with another user's goal" do
      other_user = User.create!(email_address: "other@example.com", password: password)
      other_goal = other_user.goals.create!(valid_attributes)

      expect do
        post tasks_path, params: { task: task_attributes.merge(goal_id: other_goal.id) }
      end.not_to change(Task, :count)

      expect(response).to have_http_status(:not_found)
    end

    it "creates a task without a goal" do
      post tasks_path, params: { task: task_attributes.merge(goal_id: "") }

      expect(response).to redirect_to(task_path(user.tasks.last))
      expect(user.tasks.last.goal).to be_nil
    end
  end

  it "shows factual weekly start counts on the dashboard" do
    goal = user.goals.create!(valid_attributes)
    task = user.tasks.create!(task_attributes.merge(goal: goal))
    task.start!
    task.complete!

    get root_path

    expect(response.body).to include("今週、未来に向けて着手した回数", goal.title, "1回")
  end

  def task_attributes
    { title: "応募書類を5分進める", scheduled_date: Date.current }
  end
end
