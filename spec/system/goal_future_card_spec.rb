require "rails_helper"

RSpec.describe "Goalと未来カード", type: :system do
  let!(:user) { create_user("goal-system@example.com") }

  before { sign_in_as(user) }

  it "Goalに紐づくTaskを開始すると2つの未来を表示する" do
    click_link "目標"
    click_link "+ 目標を追加"

    fill_in "目標", with: "新しい仕事に挑戦する"
    fill_in "近づきたい未来", with: "自信を持って新しい役割を担っている"
    fill_in "先延ばしした場合に続く可能性がある状態", with: "準備を始められない状態が続く"
    click_button "目標を作成"

    expect(page).to have_text("目標を作成しました。")
    click_link "+ タスクを追加"

    fill_in "タイトル", with: "応募先を1社調べる"
    select "新しい仕事に挑戦する", from: "つながる目標"
    click_button "タスクを作成"
    click_link "DoNow"

    within(find(".task-card", text: "応募先を1社調べる")) do
      click_button "5分始める"
    end

    expect(page).to have_text("応募先を1社調べる")
    expect(page).to have_current_path(focus_path)
    expect(page).to have_text("近づきたい未来")
    expect(page).to have_text("自信を持って新しい役割を担っている")
    expect(page).to have_text("先延ばしした場合に続く可能性がある状態")
    expect(page).to have_text("準備を始められない状態が続く")
  end
end
