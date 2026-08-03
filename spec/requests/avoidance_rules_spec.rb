require "rails_helper"

RSpec.describe "Avoidance rules", type: :request do
  let(:password) { "password123" }
  let(:user) { User.create!(email_address: "owner@example.com", password: password) }

  def sign_in
    post session_path, params: { email_address: user.email_address, password: password }
  end

  it "requires login for every action" do
    rule = user.avoidance_rules.create!(title: "SNSを見ない")
    requests = [
      -> { get avoidance_rules_path },
      -> { get new_avoidance_rule_path },
      -> { post avoidance_rules_path, params: { avoidance_rule: { title: "動画を見ない" } } },
      -> { get edit_avoidance_rule_path(rule) },
      -> { patch avoidance_rule_path(rule), params: { avoidance_rule: { title: "更新" } } },
      -> { delete avoidance_rule_path(rule) }
    ]

    requests.each do |request|
      request.call
      expect(response).to redirect_to(new_session_path)
    end
  end

  it "lists only the signed-in user's rules and distinguishes active status" do
    active_rule = user.avoidance_rules.create!(title: "SNSを見ない")
    inactive_rule = user.avoidance_rules.create!(title: "メールを見ない", active: false)
    other_user = User.create!(email_address: "other@example.com", password: password)
    other_rule = other_user.avoidance_rules.create!(title: "他人だけのルール")
    sign_in

    get avoidance_rules_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(active_rule.title, inactive_rule.title, "有効", "無効")
    expect(response.body).not_to include(other_rule.title)
  end

  it "creates, edits, deactivates, and deletes an owned rule" do
    sign_in

    expect do
      post avoidance_rules_path, params: { avoidance_rule: { title: " SNSを見ない ", active: "1" } }
    end.to change(user.avoidance_rules, :count).by(1)

    rule = user.avoidance_rules.last
    expect(rule.title).to eq("SNSを見ない")
    expect(response).to redirect_to(avoidance_rules_path)

    get edit_avoidance_rule_path(rule)
    expect(response).to have_http_status(:ok)

    patch avoidance_rule_path(rule), params: { avoidance_rule: { title: "動画を見ない", active: "0" } }
    expect(response).to redirect_to(avoidance_rules_path)
    expect(rule.reload.title).to eq("動画を見ない")
    expect(rule).not_to be_active

    expect { delete avoidance_rule_path(rule) }.to change(user.avoidance_rules, :count).by(-1)
    expect(response).to redirect_to(avoidance_rules_path)
  end

  it "cannot edit, update, or delete another user's rule" do
    other_user = User.create!(email_address: "other@example.com", password: password)
    other_rule = other_user.avoidance_rules.create!(title: "他人のルール")
    sign_in

    requests = [
      -> { get edit_avoidance_rule_path(other_rule) },
      -> { patch avoidance_rule_path(other_rule), params: { avoidance_rule: { title: "不正更新" } } },
      -> { delete avoidance_rule_path(other_rule) }
    ]

    requests.each do |request|
      request.call
      expect(response).to have_http_status(:not_found)
    end

    expect(other_rule.reload.title).to eq("他人のルール")
  end
end
