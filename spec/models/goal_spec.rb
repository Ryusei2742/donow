require "rails_helper"

RSpec.describe Goal, type: :model do
  let(:user) { User.create!(email_address: "owner@example.com", password: "password123") }

  def create_goal(owner: user, attributes: {})
    owner.goals.create!(
      {
        title: "Webエンジニアとして就職する",
        desired_future: "仕事の選択肢が増える未来に近づく",
        avoided_future: "学習を始められない状態が続く可能性がある"
      }.merge(attributes)
    )
  end

  it "requires a title and both future descriptions within their limits" do
    goal = described_class.new(user: user, title: nil, desired_future: nil, avoided_future: nil)

    expect(goal).not_to be_valid
    expect(goal.errors[:title]).to be_present
    expect(goal.errors[:desired_future]).to be_present
    expect(goal.errors[:avoided_future]).to be_present

    goal.assign_attributes(
      title: "目" * (described_class::TITLE_MAX_LENGTH + 1),
      desired_future: "近" * (described_class::FUTURE_MAX_LENGTH + 1),
      avoided_future: "続" * (described_class::FUTURE_MAX_LENGTH + 1)
    )

    expect(goal).not_to be_valid
    expect(goal.errors[:title]).to be_present
    expect(goal.errors[:desired_future]).to be_present
    expect(goal.errors[:avoided_future]).to be_present
  end

  it "belongs to a user and is destroyed with that user" do
    goal = create_goal

    expect(user.goals).to contain_exactly(goal)
    expect { user.destroy! }.to change(described_class, :count).by(-1)
  end

  it "keeps tasks and clears their goal when the goal is deleted" do
    goal = create_goal
    task = user.tasks.create!(title: "応募書類を開く", scheduled_date: Date.current, goal: goal)

    expect { goal.destroy! }.not_to change(Task, :count)
    expect(task.reload.goal).to be_nil
  end

  describe "#starts_this_week_count" do
    it "counts each session started this week and excludes last week's sessions" do
      Time.use_zone("Asia/Tokyo") do
        now = Time.zone.local(2026, 7, 15, 12)
        goal = create_goal
        task = user.tasks.create!(title: "ポートフォリオを進める", scheduled_date: now.to_date, goal: goal)

        create_finished_session(task, started_at: now.beginning_of_week + 1.hour)
        create_finished_session(task, started_at: now)
        create_finished_session(task, started_at: now.beginning_of_week - 1.second)

        expect(goal.starts_this_week_count(at: now)).to eq(2)
      end
    end

    it "does not include another user's work sessions" do
      now = Time.current
      goal = create_goal
      other_user = User.create!(email_address: "other@example.com", password: "password123")
      other_task = other_user.tasks.create!(title: "他人の作業", scheduled_date: Date.current)
      other_task.update_column(:goal_id, goal.id)
      create_finished_session(other_task, started_at: now)

      expect(goal.starts_this_week_count(at: now)).to eq(0)
    end
  end

  def create_finished_session(task, started_at:)
    task.work_sessions.create!(
      user: task.user,
      started_at: started_at,
      ended_at: started_at + 1.minute,
      status: :completed
    )
  end
end
