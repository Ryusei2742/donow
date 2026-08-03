module SystemHelpers
  PASSWORD = "password123"

  def create_user(email_address)
    User.create!(
      email_address: email_address,
      password: PASSWORD,
      password_confirmation: PASSWORD
    )
  end

  def sign_in_as(user)
    visit new_session_path
    fill_in "メールアドレス", with: user.email_address
    fill_in "パスワード", with: PASSWORD
    click_button "ログイン"
    expect(page).to have_text("今日のタスク")
    expect(page).to have_current_path(root_path)
  end
end

RSpec.configure do |config|
  config.include SystemHelpers, type: :system
end
