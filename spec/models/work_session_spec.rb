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
end
