require "rails_helper"

RSpec.describe AvoidanceRule, type: :model do
  let(:user) { User.create!(email_address: "owner@example.com", password: "password123") }

  it "belongs to a user and requires a title within 100 characters" do
    rule = described_class.new(user: nil, title: "")

    expect(rule).not_to be_valid
    expect(rule.errors[:user]).to be_present
    expect(rule.errors[:title]).to be_present

    rule.user = user
    rule.title = "あ" * 101
    expect(rule).not_to be_valid
    expect(rule.errors[:title]).to be_present
  end

  it "strips surrounding whitespace and prevents case-insensitive duplicates for one user" do
    first_rule = user.avoidance_rules.create!(title: "  YouTubeを開かない  ")
    duplicate = user.avoidance_rules.new(title: "youtubeを開かない")

    expect(first_rule.title).to eq("YouTubeを開かない")
    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:title]).to be_present
  end

  it "allows different users to register the same title" do
    other_user = User.create!(email_address: "other@example.com", password: "password123")

    expect(user.avoidance_rules.create!(title: "SNSを見ない")).to be_persisted
    expect(other_user.avoidance_rules.create!(title: "SNSを見ない")).to be_persisted
  end

  it "is destroyed with its user" do
    user.avoidance_rules.create!(title: "別のタスクに移らない")

    expect { user.destroy! }.to change(described_class, :count).by(-1)
  end

  it "nullifies the association while preserving a work session title snapshot when deleted" do
    rule = user.avoidance_rules.create!(title: "SNSを見ない")
    task = user.tasks.create!(title: "企画書を開く")
    work_session = task.start!(
      planned_duration_seconds: 5.minutes.to_i,
      avoidance_rule: rule
    )

    rule.destroy!

    expect(work_session.reload.avoidance_rule).to be_nil
    expect(work_session.avoidance_rule_title).to eq("SNSを見ない")
  end
end
