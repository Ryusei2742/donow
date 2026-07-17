class CreateGoalsAndLinkTasks < ActiveRecord::Migration[8.1]
  def change
    create_table :goals do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.text :desired_future, null: false
      t.text :avoided_future, null: false
      t.date :target_date

      t.timestamps
    end

    add_reference :tasks,
                  :goal,
                  null: true,
                  foreign_key: { on_delete: :nullify }
  end
end
