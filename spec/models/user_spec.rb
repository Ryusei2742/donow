require "rails_helper"

RSpec.describe User, type: :model do
  it "normalizes email addresses and owns tasks" do
    user = described_class.create!(email_address: " Owner@Example.COM ", password: "password123")
    task = user.tasks.create!(title: "自分のタスク", scheduled_date: Date.current)

    expect(user.email_address).to eq("owner@example.com")
    expect(user.tasks).to contain_exactly(task)
  end

  it "destroys owned tasks" do
    user = described_class.create!(email_address: "owner@example.com", password: "password123")
    user.tasks.create!(title: "削除されるタスク", scheduled_date: Date.current)

    expect { user.destroy! }.to change(Task, :count).by(-1)
  end
end
