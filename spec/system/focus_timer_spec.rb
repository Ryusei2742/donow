require "rails_helper"

RSpec.describe "タスクから5分タイマーを使う", type: :system do
  let!(:user) { create_user("focus-system@example.com") }
  let!(:avoidance_rule) { user.avoidance_rules.create!(title: "動画サイトを開かない") }

  before { sign_in_as(user) }

  it "タスクを作成して開始し、待たずに延長・中断してダッシュボードへ戻れる" do
    click_link "今日のタスクを追加"
    fill_in "タイトル", with: "企画書の見出しを書く"
    click_button "タスクを作成"
    click_link "DoNow"

    within(find(".task-card", text: "企画書の見出しを書く")) do
      select avoidance_rule.title, from: "この5分でやらないこと"
      click_button "5分始める"
    end

    expect(page).to have_text("企画書の見出しを書く")
    expect(page).to have_text(avoidance_rule.title)
    expect(page).to have_current_path(focus_path)
    expect(page).to have_css("[data-controller~='countdown'][data-countdown-ready='true']")
    expect(page).to have_css("[data-countdown-target='display']")
    expect(page).to have_button("中断する")

    task = user.tasks.find_by!(title: "企画書の見出しを書く")
    session = user.work_sessions.open.focus_timers.find_by!(task: task)
    session.update!(started_at: 6.minutes.ago)
    visit focus_path

    expect(page).to have_button("5分延長する")
    click_button "5分延長する"

    expect(page).to have_text("タイマーを5分延長しました。")
    expect(page).to have_text(avoidance_rule.title)
    expect(session.reload.planned_duration_seconds).to eq(10.minutes.to_i)

    click_button "中断する"

    expect(page).to have_text("作業を中断しました。")
    expect(session.reload).to be_interrupted
    click_link "今日の画面へ戻る"
    expect(page).to have_text("今日のタスク")
    expect(page).to have_current_path(root_path)
  end
end
