require "rails_helper"

RSpec.describe "DoNow pages", type: :request do
  let(:user) { User.create!(email_address: "owner@example.com", password: "password123") }

  before do
    post session_path, params: { email_address: user.email_address, password: "password123" }
  end

  def create_task(attributes = {})
    user.tasks.create!(
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

    it "starts a dashboard task with one POST and shows the timer" do
      task = create_task

      get root_path
      document = Nokogiri::HTML(response.body)
      start_form = document.at_css(
        "form[action='#{start_focus_path}'] input[name='task_id'][value='#{task.id}']"
      )
      expect(start_form).to be_present
      expect(response.body).to include("5分始める")

      expect do
        post start_focus_path, params: { task_id: task.id }
      end.to change(user.work_sessions, :count).by(1)

      expect(response).to redirect_to(focus_path)
      follow_redirect!
      expect(response.body).to include(task.title, "5:00")
      expect(task.reload).to be_active
    end

    it "shows the last started incomplete task as the previous task and resumes it with one POST" do
      older_task = create_task(title: "先に着手したタスク")
      recent_task = create_task(title: "前回のタスク")
      older_session = older_task.start!(planned_duration_seconds: 5.minutes.to_i)
      older_task.interrupt!
      recent_session = recent_task.start!(planned_duration_seconds: 5.minutes.to_i)
      recent_task.interrupt!
      older_session.update_column(:started_at, 2.days.ago)
      recent_session.update_column(:started_at, 1.hour.ago)

      get root_path

      document = Nokogiri::HTML(response.body)
      expect(response.body).to include("前回の続き", recent_task.title)
      expect(
        document.at_css(
          ".resume-card form[action='#{start_focus_path}'] input[name='task_id'][value='#{recent_task.id}']"
        )
      ).to be_present

      post start_focus_path, params: { task_id: recent_task.id }
      expect(response).to redirect_to(focus_path)
    end

    it "does not show a start button for completed or skipped tasks" do
      completed_task = create_task(title: "完了済み", status: :completed, completed_at: Time.current)
      skipped_task = create_task(title: "スキップ済み", status: :skipped)

      get root_path

      document = Nokogiri::HTML(response.body)
      expect(response.body).to include(completed_task.title, skipped_task.title)
      expect(document.at_css("input[name='task_id'][value='#{completed_task.id}']")).to be_nil
      expect(document.at_css("input[name='task_id'][value='#{skipped_task.id}']")).to be_nil
    end
  end

  describe "POST /quick_start" do
    it "creates today's active task and a five-minute work session" do
      expect do
        post quick_start_path, params: { task: { title: "請求書を開く" } }
      end.to change(user.tasks, :count).by(1).and change(user.work_sessions, :count).by(1)

      task = user.tasks.last
      work_session = user.work_sessions.last

      expect(response).to redirect_to(focus_path)
      expect(task.title).to eq("請求書を開く")
      expect(task.scheduled_date).to eq(Date.current)
      expect(task).to be_active
      expect(task.goal).to be_nil
      expect(work_session.task).to eq(task)
      expect(work_session).to be_active
      expect(work_session.planned_duration_seconds).to eq(5.minutes.to_i)
    end

    it "renders a dashboard error without creating records when title is blank" do
      expect do
        post quick_start_path, params: { task: { title: "" } }
      end.to change(user.tasks, :count).by(0).and change(user.work_sessions, :count).by(0)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("今からやることを入力してください", "名前だけ決めて、今すぐ5分")
    end

    it "restores an active focus session without creating a duplicate task or session" do
      active_task = create_task(title: "進行中のタスク")
      active_session = active_task.start!(planned_duration_seconds: 5.minutes.to_i)

      expect do
        post quick_start_path, params: { task: { title: "重複させないタスク" } }
      end.to change(user.tasks, :count).by(0).and change(user.work_sessions, :count).by(0)

      expect(response).to redirect_to(focus_path)
      follow_redirect!
      expect(response.body).to include(active_task.title)
      expect(user.work_sessions.open).to contain_exactly(active_session)
    end

    it "stores the selected avoidance rule" do
      rule = user.avoidance_rules.create!(title: "別のタスクに移らない")

      post quick_start_path,
           params: { task: { title: "請求書を開く" }, avoidance_rule_id: rule.id }

      work_session = user.work_sessions.last
      expect(response).to redirect_to(focus_path)
      expect(work_session.avoidance_rule).to eq(rule)
      expect(work_session.avoidance_rule_title).to eq(rule.title)
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
