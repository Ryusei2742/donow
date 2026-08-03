class CreateAvoidanceRules < ActiveRecord::Migration[8.1]
  def change
    create_table :avoidance_rules do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false, limit: 100
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :avoidance_rules,
              "user_id, LOWER(title)",
              unique: true,
              name: "index_avoidance_rules_on_user_and_lower_title"
  end
end
