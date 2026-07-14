class AddUserToTasks < ActiveRecord::Migration[8.1]
  class MigrationUser < ActiveRecord::Base
    self.table_name = "users"
  end

  class MigrationTask < ActiveRecord::Base
    self.table_name = "tasks"
  end

  def up
    add_reference :tasks, :user, null: true, foreign_key: true

    MigrationTask.reset_column_information
    backfill_existing_tasks if MigrationTask.where(user_id: nil).exists?

    change_column_null :tasks, :user_id, false
  end

  def down
    remove_reference :tasks, :user, foreign_key: true
  end

  private

  def backfill_existing_tasks
    legacy_user = MigrationUser.find_or_create_by!(email_address: "legacy-tasks@localhost.invalid") do |user|
      user.password_digest = BCrypt::Password.create(SecureRandom.hex(32))
    end

    MigrationTask.where(user_id: nil).update_all(user_id: legacy_user.id)
  end
end
