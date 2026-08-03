require "rails_helper"

RSpec.describe WorkSession, type: :model do
  let(:user) { User.create!(email_address: "owner@example.com", password: "password123") }
  let(:task) { Task.create!(user: user, title: "企画書を開く", scheduled_date: Date.current) }

  it "requires a task, started_at, and status" do
    session = described_class.new(task: nil, started_at: nil, status: nil)

    expect(session).not_to be_valid
    expect(session.errors[:task]).to be_present
    expect(session.errors[:started_at]).to be_present
    expect(session.errors[:status]).to be_present
  end

  it "defaults a new session to active" do
    session = described_class.new(task: task, started_at: Time.current)

    expect(session).to be_active
    expect(session).to be_valid
    expect(session.user).to eq(user)
  end

  it "does not allow ended_at before started_at" do
    started_at = Time.current
    session = described_class.new(
      task: task,
      started_at: started_at,
      ended_at: started_at - 1.minute,
      status: :interrupted
    )

    expect(session).not_to be_valid
    expect(session.errors[:ended_at]).to be_present
  end

  it "does not allow a user to have multiple active sessions" do
    first_task = task
    second_task = user.tasks.create!(title: "次のタスク", scheduled_date: Date.current)
    described_class.create!(task: first_task, started_at: Time.current)
    duplicate = described_class.new(task: second_task, started_at: Time.current)

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:status]).to be_present
  end

  it "calculates the timer end and remaining time from started_at" do
    started_at = Time.zone.parse("2026-07-18 10:00:00")
    session = described_class.new(
      task: task,
      started_at: started_at,
      planned_duration_seconds: 5.minutes.to_i
    )

    expect(session.ends_at).to eq(started_at + 5.minutes)
    expect(session.remaining_seconds(at: started_at + 2.minutes)).to eq(3.minutes.to_i)
  end

  it "stores an owned avoidance rule and snapshots its title" do
    rule = user.avoidance_rules.create!(title: "YouTubeを開かない")
    session = described_class.create!(task: task, started_at: Time.current, avoidance_rule: rule)

    expect(session.avoidance_rule).to eq(rule)
    expect(session.avoidance_rule_title).to eq(rule.title)
  end

  it "rejects another user's avoidance rule" do
    other_user = User.create!(email_address: "other@example.com", password: "password123")
    other_rule = other_user.avoidance_rules.create!(title: "他人のルール")
    session = described_class.new(task: task, started_at: Time.current, avoidance_rule: other_rule)

    expect(session).not_to be_valid
    expect(session.errors[:avoidance_rule]).to be_present
  end
end
