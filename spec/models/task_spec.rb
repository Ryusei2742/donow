require "rails_helper"

RSpec.describe Task, type: :model do
  let(:user) { User.create!(email_address: "owner@example.com", password: "password123") }

  describe "validations and defaults" do
    it "requires title, status, and scheduled date" do
      task = described_class.new(user: user, title: nil, status: nil, scheduled_date: nil)

      expect(task).not_to be_valid
      expect(task.errors[:title]).to be_present
      expect(task.errors[:status]).to be_present
      expect(task.errors[:scheduled_date]).to be_present
    end

    it "defaults a new task to pending and today" do
      task = described_class.new(user: user, title: "5分だけ始める")

      expect(task).to be_pending
      expect(task.scheduled_date).to eq(Date.current)
      expect(task).to be_valid
    end
  end

  describe "work actions" do
    let(:task) do
      described_class.create!(
        user: user,
        title: "企画書を開く",
        scheduled_date: Date.current,
        estimated_minutes: 5
      )
    end

    describe "#start!" do
      it "activates the task and creates only one open work session" do
        expect { task.start! }.to change { task.work_sessions.count }.by(1)

        expect(task).to be_active
        expect(task.open_work_session).to be_active
        expect { task.start! }.not_to change { task.work_sessions.count }
      end
    end

    describe "#complete!" do
      it "timestamps the task and completes its open work session" do
        task.start!
        session = task.open_work_session

        task.complete!

        expect(task).to be_completed
        expect(task.completed_at).to be_present
        expect(session.reload).to be_completed
        expect(session.ended_at).to be_present
      end
    end

    describe "#interrupt!" do
      it "returns the task to pending and interrupts its open work session" do
        task.start!
        session = task.open_work_session

        task.interrupt!

        expect(task).to be_pending
        expect(session.reload).to be_interrupted
        expect(session.ended_at).to be_present
      end
    end

    describe "#skip!" do
      it "skips the task and interrupts its open work session" do
        task.start!
        session = task.open_work_session

        task.skip!

        expect(task).to be_skipped
        expect(session.reload).to be_interrupted
        expect(session.ended_at).to be_present
      end
    end
  end
end
