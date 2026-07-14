require "test_helper"

class WorkSessionTest < ActiveSupport::TestCase
  test "task, started_at and status are required" do
    session = WorkSession.new(task: nil, started_at: nil, status: nil)

    assert_not session.valid?
    assert session.errors[:task].any?
    assert session.errors[:started_at].any?
    assert session.errors[:status].any?
  end

  test "new session defaults to active" do
    session = WorkSession.new(task: tasks(:today_pending), started_at: Time.current)

    assert_predicate session, :active?
    assert_predicate session, :valid?
  end

  test "ended_at cannot be before started_at" do
    session = WorkSession.new(
      task: tasks(:today_pending),
      started_at: Time.current,
      ended_at: 1.minute.ago,
      status: :interrupted
    )

    assert_not session.valid?
    assert session.errors[:ended_at].any?
  end
end
