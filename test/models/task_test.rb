require "test_helper"

class TaskTest < ActiveSupport::TestCase
  test "title, status and scheduled date are required" do
    task = Task.new(title: nil, status: nil, scheduled_date: nil)

    assert_not task.valid?
    assert task.errors[:title].any?
    assert task.errors[:status].any?
    assert task.errors[:scheduled_date].any?
  end

  test "new task defaults to pending and today" do
    task = Task.new(title: "5分だけ始める")

    assert_predicate task, :pending?
    assert_equal Date.current, task.scheduled_date
    assert_predicate task, :valid?
  end

  test "start creates one active work session" do
    task = tasks(:today_pending)

    assert_difference -> { task.work_sessions.count }, 1 do
      task.start!
    end

    assert_predicate task, :active?
    assert_predicate task.open_work_session, :active?

    assert_no_difference -> { task.work_sessions.count } do
      task.start!
    end
  end

  test "complete timestamps task and closes active session" do
    task = tasks(:today_active)
    session = work_sessions(:active_session)

    task.complete!

    assert_predicate task, :completed?
    assert_not_nil task.completed_at
    assert_predicate session.reload, :completed?
    assert_not_nil session.ended_at
  end

  test "interrupt returns task to pending and interrupts session" do
    task = tasks(:today_active)
    session = work_sessions(:active_session)

    task.interrupt!

    assert_predicate task, :pending?
    assert_predicate session.reload, :interrupted?
    assert_not_nil session.ended_at
  end
end
