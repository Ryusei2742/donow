require "test_helper"

class PagesTest < ActionDispatch::IntegrationTest
  test "main pages render successfully" do
    get root_path
    assert_response :success
    assert_select "h1", "DoNow"

    get tasks_path
    assert_response :success

    get task_path(tasks(:today_pending))
    assert_response :success

    get new_task_path
    assert_response :success

    get focus_path
    assert_response :success
    assert_select "[data-controller='countdown']"

    get history_path
    assert_response :success
  end

  test "task actions change state and work sessions" do
    task = tasks(:today_pending)

    assert_difference -> { task.work_sessions.count }, 1 do
      patch start_task_path(task)
    end
    assert_redirected_to task_path(task)
    assert_predicate task.reload, :active?

    patch complete_task_path(task)
    assert_redirected_to task_path(task)
    assert_predicate task.reload, :completed?
    assert_predicate task.work_sessions.last, :completed?
  end
end
