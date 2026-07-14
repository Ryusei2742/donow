class CreateWorkSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :work_sessions do |t|
      t.references :task, null: false, foreign_key: true
      t.datetime :started_at, null: false
      t.datetime :ended_at
      t.string :status, null: false, default: "active"

      t.timestamps
    end

    add_index :work_sessions, [ :task_id, :status ]
    add_index :work_sessions, :started_at
  end
end
