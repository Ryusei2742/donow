class AddFocusTimerToWorkSessions < ActiveRecord::Migration[8.1]
  def up
    add_reference :work_sessions, :user, foreign_key: true
    add_column :work_sessions, :planned_duration_seconds, :integer

    execute <<~SQL
      UPDATE work_sessions
      SET user_id = tasks.user_id
      FROM tasks
      WHERE work_sessions.task_id = tasks.id
    SQL

    execute <<~SQL
      WITH duplicate_active_sessions AS (
        SELECT work_sessions.id,
               ROW_NUMBER() OVER (
                 PARTITION BY work_sessions.user_id
                 ORDER BY work_sessions.started_at DESC, work_sessions.id DESC
               ) AS active_position
        FROM work_sessions
        WHERE work_sessions.status = 'active'
          AND work_sessions.ended_at IS NULL
      )
      UPDATE work_sessions
      SET status = 'interrupted', ended_at = CURRENT_TIMESTAMP
      FROM duplicate_active_sessions
      WHERE work_sessions.id = duplicate_active_sessions.id
        AND duplicate_active_sessions.active_position > 1
    SQL

    change_column_null :work_sessions, :user_id, false
    add_index :work_sessions,
              :user_id,
              unique: true,
              where: "status = 'active' AND ended_at IS NULL",
              name: "index_work_sessions_on_one_active_per_user"
    add_check_constraint :work_sessions,
                         "planned_duration_seconds IS NULL OR planned_duration_seconds > 0",
                         name: "work_sessions_positive_planned_duration"
  end

  def down
    remove_check_constraint :work_sessions, name: "work_sessions_positive_planned_duration"
    remove_index :work_sessions, name: "index_work_sessions_on_one_active_per_user"
    remove_column :work_sessions, :planned_duration_seconds
    remove_reference :work_sessions, :user, foreign_key: true
  end
end
