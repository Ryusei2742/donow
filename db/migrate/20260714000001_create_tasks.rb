class CreateTasks < ActiveRecord::Migration[8.1]
  def change
    create_table :tasks do |t|
      t.string :title, null: false
      t.text :description
      t.string :status, null: false, default: "pending"
      t.date :scheduled_date, null: false
      t.integer :estimated_minutes
      t.datetime :completed_at

      t.timestamps
    end

    add_index :tasks, :scheduled_date
    add_index :tasks, :status
  end
end
