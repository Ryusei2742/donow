require "rails_helper"

RSpec.describe "ユーザー登録とログイン", type: :system do
  it "登録後にダッシュボードを表示し、ログアウトして再ログインできる" do
    visit new_registration_path

    fill_in "メールアドレス", with: "system-user@example.com"
    fill_in "パスワード", with: "password123"
    fill_in "パスワード（確認）", with: "password123"
    click_button "登録する"

    expect(page).to have_text("今日のタスク")
    expect(page).to have_text("system-user@example.com")
    expect(page).to have_current_path(root_path)

    click_button "ログアウト"

    expect(page).to have_css("h1", text: "ログイン")
    expect(page).to have_current_path(new_session_path)

    fill_in "メールアドレス", with: "system-user@example.com"
    fill_in "パスワード", with: "password123"
    click_button "ログイン"

    expect(page).to have_text("今日のタスク")
    expect(page).to have_current_path(root_path)
  end
end
