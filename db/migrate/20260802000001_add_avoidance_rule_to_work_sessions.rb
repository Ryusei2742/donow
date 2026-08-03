class AddAvoidanceRuleToWorkSessions < ActiveRecord::Migration[8.1]
  def change
    add_reference :work_sessions,
                  :avoidance_rule,
                  null: true,
                  foreign_key: { on_delete: :nullify }
    add_column :work_sessions, :avoidance_rule_title, :string, limit: 100
  end
end
