require "rails_helper"

RSpec.describe "Authentication", type: :request do
  let(:password) { "password123" }
  let(:user) { User.create!(email_address: "owner@example.com", password: password) }

  def sign_in(as: user)
    post session_path, params: { email_address: as.email_address, password: password }
  end

  describe "registration" do
    it "creates a user and signs them in" do
      expect do
        post registration_path, params: {
          user: {
            email_address: " NewUser@Example.com ",
            password: password,
            password_confirmation: password
          }
        }
      end.to change(User, :count).by(1).and change(Session, :count).by(1)

      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(response.body).to include("newuser@example.com", "ログアウト")
    end
  end

  describe "login and logout" do
    it "logs in with valid credentials" do
      sign_in

      expect(response).to redirect_to(root_url)
      follow_redirect!
      expect(response.body).to include(user.email_address)
    end

    it "logs out and prevents further authenticated access" do
      sign_in

      expect { delete session_path }.to change(Session, :count).by(-1)
      expect(response).to redirect_to(new_session_path)

      get root_path
      expect(response).to redirect_to(new_session_path)
    end
  end

  describe "access control" do
    it "redirects unauthenticated requests to login" do
      get root_path

      expect(response).to redirect_to(new_session_path)
    end

    it "shows only the signed-in user's tasks on dashboard, task list, and history" do
      own_task = user.tasks.create!(title: "自分だけに見える", scheduled_date: Date.current)
      other_user = User.create!(email_address: "other@example.com", password: password)
      other_task = other_user.tasks.create!(title: "他人のタスク", scheduled_date: Date.current)
      other_task.start!
      sign_in

      [root_path, tasks_path, history_path].each do |path|
        get path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include(own_task.title)
        expect(response.body).not_to include(other_task.title)
      end
    end

    it "does not expose another user's task in five-minute mode" do
      other_user = User.create!(email_address: "other@example.com", password: password)
      other_task = other_user.tasks.create!(title: "他人の5分タスク", scheduled_date: Date.current)
      sign_in

      get focus_path(task_id: other_task.id)

      expect(response).to have_http_status(:not_found)
    end

    it "cannot view, edit, update, delete, start, interrupt, complete, or skip another user's task" do
      other_user = User.create!(email_address: "other@example.com", password: password)
      other_task = other_user.tasks.create!(title: "変更不可", scheduled_date: Date.current)
      sign_in

      requests = [
        -> { get task_path(other_task) },
        -> { get edit_task_path(other_task) },
        -> { patch task_path(other_task), params: { task: { title: "不正更新" } } },
        -> { delete task_path(other_task) },
        -> { patch start_task_path(other_task) },
        -> { patch interrupt_task_path(other_task) },
        -> { patch complete_task_path(other_task) },
        -> { patch skip_task_path(other_task) }
      ]

      requests.each do |request|
        request.call
        expect(response).to have_http_status(:not_found)
      end

      expect(other_task.reload).to be_pending
      expect(other_task.title).to eq("変更不可")
      expect(other_task.work_sessions).to be_empty
    end
  end
end
