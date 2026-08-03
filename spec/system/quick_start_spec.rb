require "rails_helper"

RSpec.describe "クイックスタート", type: :system do
  let!(:user) { create_user("quick-start-system@example.com") }
  let!(:avoidance_rule) { user.avoidance_rules.create!(title: "メールを開かない") }

  before { sign_in_as(user) }

  it "タイトルとやらないことだけでTaskとWorkSessionを作り、タイマーへ移動する" do
    within(".quick-start-panel") do
      fill_in "今からやること", with: "資料を1ページ読む"
      select avoidance_rule.title, from: "この5分でやらないこと"
      click_button "作って5分始める"
    end

    expect(page).to have_text("資料を1ページ読む")
    expect(page).to have_text(avoidance_rule.title)
    expect(page).to have_current_path(focus_path)

    task = user.tasks.find_by!(title: "資料を1ページ読む")
    session = user.work_sessions.find_by!(task: task)
    expect(task).to be_active
    expect(task.scheduled_date).to eq(Date.current)
    expect(session).to be_active
    expect(session.planned_duration_seconds).to eq(5.minutes.to_i)
    expect(session.avoidance_rule).to eq(avoidance_rule)
  end
end
