require "rails_helper"

RSpec.describe "Focus timer", type: :request do
  let(:password) { "password123" }
  let(:user) { User.create!(email_address: "owner@example.com", password: password) }
  let(:task) { user.tasks.create!(title: "企画書を5分進める", scheduled_date: Date.current) }

  before do
    post session_path, params: { email_address: user.email_address, password: password }
  end

  describe "starting and restoring" do
    it "starts the selected task and creates a five-minute work session" do
      expect do
        post start_focus_path, params: { task_id: task.id }
      end.to change(user.work_sessions, :count).by(1)

      session = user.work_sessions.last
      expect(response).to redirect_to(focus_path)
      expect(task.reload).to be_active
      expect(session).to be_active
      expect(session.task).to eq(task)
      expect(session.planned_duration_seconds).to eq(5.minutes.to_i)
    end

    it "restores the active timer from its server-side start time and duration" do
      session = task.start!(planned_duration_seconds: 5.minutes.to_i)
      session.update_column(:started_at, 2.minutes.ago)

      get focus_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(task.title)
      expect(response.body).to include("data-countdown-end-at-value=\"#{session.reload.ends_at.iso8601(3)}\"")
      expect(response.body).to match(/(?:3:00|2:5\d)/)
    end

    it "reuses the same active timer instead of resetting it" do
      session = task.start!(planned_duration_seconds: 5.minutes.to_i)
      original_started_at = session.started_at

      expect do
        post start_focus_path, params: { task_id: task.id }
      end.not_to change(user.work_sessions, :count)

      expect(session.reload.started_at).to eq(original_started_at)
      expect(session.planned_duration_seconds).to eq(5.minutes.to_i)
    end

    it "starts a fresh five-minute timer when switching from ordinary work" do
      ordinary_session = task.start!

      expect do
        post start_focus_path, params: { task_id: task.id }
      end.to change(user.work_sessions, :count).by(1)

      expect(ordinary_session.reload).to be_interrupted
      expect(ordinary_session.ended_at).to be_present
      expect(user.work_sessions.open.first.planned_duration_seconds).to eq(5.minutes.to_i)
    end

    it "shows all outcome choices when a restored timer has expired" do
      session = task.start!(planned_duration_seconds: 5.minutes.to_i)
      session.update_column(:started_at, 6.minutes.ago)

      get focus_path

      expect(response.body).to include("0:00", "完了する", "5分延長する", "10分延長する", "中断する")
      expect(response.body).to include('class="focus-outcome" data-countdown-target="outcome" >')
    end
  end

  describe "timer actions" do
    let!(:work_session) { task.start!(planned_duration_seconds: 5.minutes.to_i) }

    it "extends the timer by five minutes on the server" do
      expect do
        patch extend_focus_path(work_session), params: { seconds: 5.minutes.to_i }
      end.to change { work_session.reload.planned_duration_seconds }.from(5.minutes.to_i).to(10.minutes.to_i)

      expect(response).to redirect_to(focus_path)
      expect(work_session).to be_active
    end

    it "extends the timer by ten minutes on the server" do
      expect do
        patch extend_focus_path(work_session), params: { seconds: 10.minutes.to_i }
      end.to change { work_session.reload.planned_duration_seconds }.from(5.minutes.to_i).to(15.minutes.to_i)
    end

    it "completes the task and active work session" do
      patch complete_focus_path(work_session)

      expect(response).to redirect_to(focus_path)
      expect(task.reload).to be_completed
      expect(work_session.reload).to be_completed
      expect(work_session.ended_at).to be_present
    end

    it "interrupts the task and active work session" do
      patch interrupt_focus_path(work_session)

      expect(response).to redirect_to(focus_path)
      expect(task.reload).to be_pending
      expect(work_session.reload).to be_interrupted
      expect(work_session.ended_at).to be_present
    end
  end

  describe "access control" do
    let(:other_user) { User.create!(email_address: "other@example.com", password: password) }
    let(:other_task) { other_user.tasks.create!(title: "他人の集中タスク", scheduled_date: Date.current) }
    let!(:other_session) { other_task.start!(planned_duration_seconds: 5.minutes.to_i) }

    it "requires login for the focus timer" do
      delete session_path

      get focus_path
      expect(response).to redirect_to(new_session_path)

      post start_focus_path, params: { task_id: task.id }
      expect(response).to redirect_to(new_session_path)
    end

    it "cannot start a timer for another user's task" do
      post start_focus_path, params: { task_id: other_task.id }

      expect(response).to have_http_status(:not_found)
    end

    it "cannot extend, complete, or interrupt another user's work session" do
      requests = [
        -> { patch extend_focus_path(other_session), params: { seconds: 5.minutes.to_i } },
        -> { patch complete_focus_path(other_session) },
        -> { patch interrupt_focus_path(other_session) }
      ]

      requests.each do |request|
        request.call
        expect(response).to have_http_status(:not_found)
      end

      expect(other_task.reload).to be_active
      expect(other_session.reload).to be_active
      expect(other_session.planned_duration_seconds).to eq(5.minutes.to_i)
    end
  end
end
