require "rails_helper"

RSpec.describe "やらないことの管理", type: :system do
  let!(:user) { create_user("avoidance-system@example.com") }

  before { sign_in_as(user) }

  it "ナビゲーションから登録・編集・無効化でき、無効な項目を開始時に表示しない" do
    click_link "やらないこと"
    click_link "+ 新しく登録"

    fill_in "この5分では避けたい行動", with: "SNSを見ない"
    click_button "登録する"

    expect(page).to have_text("やらないことを登録しました。")
    expect(page).to have_text("SNSを見ない")

    within(find(".avoidance-rule-card", text: "SNSを見ない")) do
      click_link "編集"
    end

    fill_in "この5分では避けたい行動", with: "SNSとニュースを見ない"
    uncheck "有効にする"
    click_button "変更を保存"

    within(find(".avoidance-rule-card", text: "SNSとニュースを見ない")) do
      expect(page).to have_text("無効")
    end

    click_link "今日"

    within(".quick-start-panel") do
      expect(page).to have_select("この5分でやらないこと", options: [ "選択しない" ])
    end
  end
end
