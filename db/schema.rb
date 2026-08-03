# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_08_02_000001) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "avoidance_rules", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.string "title", limit: 100, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index "user_id, lower((title)::text)", name: "index_avoidance_rules_on_user_and_lower_title", unique: true
    t.index ["user_id"], name: "index_avoidance_rules_on_user_id"
  end

  create_table "goals", force: :cascade do |t|
    t.text "avoided_future", null: false
    t.datetime "created_at", null: false
    t.text "desired_future", null: false
    t.date "target_date"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_goals_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "tasks", force: :cascade do |t|
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "estimated_minutes"
    t.bigint "goal_id"
    t.date "scheduled_date", null: false
    t.string "status", default: "pending", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["goal_id"], name: "index_tasks_on_goal_id"
    t.index ["scheduled_date"], name: "index_tasks_on_scheduled_date"
    t.index ["status"], name: "index_tasks_on_status"
    t.index ["user_id"], name: "index_tasks_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  create_table "work_sessions", force: :cascade do |t|
    t.bigint "avoidance_rule_id"
    t.string "avoidance_rule_title", limit: 100
    t.datetime "created_at", null: false
    t.datetime "ended_at"
    t.integer "planned_duration_seconds"
    t.datetime "started_at", null: false
    t.string "status", default: "active", null: false
    t.bigint "task_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["avoidance_rule_id"], name: "index_work_sessions_on_avoidance_rule_id"
    t.index ["started_at"], name: "index_work_sessions_on_started_at"
    t.index ["task_id", "status"], name: "index_work_sessions_on_task_id_and_status"
    t.index ["task_id"], name: "index_work_sessions_on_task_id"
    t.index ["user_id"], name: "index_work_sessions_on_one_active_per_user", unique: true, where: "(((status)::text = 'active'::text) AND (ended_at IS NULL))"
    t.index ["user_id"], name: "index_work_sessions_on_user_id"
    t.check_constraint "planned_duration_seconds IS NULL OR planned_duration_seconds > 0", name: "work_sessions_positive_planned_duration"
  end

  add_foreign_key "avoidance_rules", "users"
  add_foreign_key "goals", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "tasks", "goals", on_delete: :nullify
  add_foreign_key "tasks", "users"
  add_foreign_key "work_sessions", "avoidance_rules", on_delete: :nullify
  add_foreign_key "work_sessions", "tasks"
  add_foreign_key "work_sessions", "users"
end
