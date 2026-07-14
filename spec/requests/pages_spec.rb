require "rails_helper"

RSpec.describe "DoNow pages", type: :request do
  def create_task(attributes = {})
    Task.create!(
      {
        title: "企画書を開く",
        scheduled_date: Date.current
      }.merge(attributes)
    )
  end

  describe "GET /" do
    it "renders the dashboard with today's task counts" do
      pending_task = create_task
      active_task = create_task(title: "メールを返す", status: :active)
      create_task(title: "完了したタスク", status: :completed, completed_at: Time.current)
      active_task.work_sessions.create!(started_at: Time.current, status: :active)

      get root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("DoNow")
      expect(response.body).to include("やる気ではなく、着手を記録する")
      expect(response.body).to include(pending_task.title, active_task.title)
      expect(response.body).to include("完了", "未完了", "着手済み")
    end
  end

  describe "main pages" do
    it "renders the task, focus, and history pages" do
      task = create_task

      get tasks_path
      expect(response).to have_http_status(:ok)

      get task_path(task)
      expect(response).to have_http_status(:ok)

      get new_task_path
      expect(response).to have_http_status(:ok)

      get focus_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('data-controller="countdown"')

      get history_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "task actions" do
    it "starts a task and creates a work session" do
      task = create_task

      expect { patch start_task_path(task) }.to change { task.work_sessions.count }.by(1)

      expect(response).to redirect_to(task_path(task))
      expect(task.reload).to be_active
      expect(task.open_work_session).to be_active
    end

    it "interrupts an active task and its work session" do
      task = create_task
      task.start!
      session = task.open_work_session

      patch interrupt_task_path(task)

      expect(response).to redirect_to(task_path(task))
      expect(task.reload).to be_pending
      expect(session.reload).to be_interrupted
      expect(session.ended_at).to be_present
    end

    it "completes an active task and its work session" do
      task = create_task
      task.start!
      session = task.open_work_session

      patch complete_task_path(task)

      expect(response).to redirect_to(task_path(task))
      expect(task.reload).to be_completed
      expect(task.completed_at).to be_present
      expect(session.reload).to be_completed
      expect(session.ended_at).to be_present
    end

    it "skips a task" do
      task = create_task

      patch skip_task_path(task)

      expect(response).to redirect_to(task_path(task))
      expect(task.reload).to be_skipped
    end
  end
end
