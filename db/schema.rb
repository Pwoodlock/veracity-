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

ActiveRecord::Schema[8.0].define(version: 2025_10_15_190212) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "backup_configurations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "repository_url"
    t.string "repository_type", default: "borgbase", null: false
    t.text "encrypted_passphrase"
    t.text "encrypted_ssh_key"
    t.string "backup_schedule", default: "0 2 * * *"
    t.datetime "last_backup_at"
    t.datetime "next_backup_at"
    t.boolean "enabled", default: false, null: false
    t.integer "retention_daily", default: 7
    t.integer "retention_weekly", default: 4
    t.integer "retention_monthly", default: 6
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "encrypted_passphrase_iv"
    t.string "encrypted_ssh_key_iv"
  end

  create_table "backup_histories", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "backup_name", null: false
    t.string "status", default: "pending", null: false
    t.datetime "started_at"
    t.datetime "completed_at"
    t.integer "duration_seconds"
    t.bigint "original_size"
    t.bigint "compressed_size"
    t.bigint "deduplicated_size"
    t.integer "files_count"
    t.text "error_message"
    t.text "output"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "backup_configuration_id"
    t.index ["backup_configuration_id"], name: "index_backup_histories_on_backup_configuration_id"
    t.index ["started_at"], name: "index_backup_histories_on_started_at"
    t.index ["status"], name: "index_backup_histories_on_status"
  end

  create_table "commands", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "server_id", null: false
    t.string "command_type"
    t.text "command"
    t.jsonb "arguments"
    t.string "status"
    t.text "output"
    t.text "error_output"
    t.integer "exit_code"
    t.float "duration_seconds"
    t.string "salt_job_id"
    t.datetime "started_at"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "task_execution_id"
    t.index ["server_id"], name: "index_commands_on_server_id"
    t.index ["task_execution_id"], name: "index_commands_on_task_execution_id"
  end

  create_table "groups", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.text "description"
    t.string "color", default: "#3B82F6"
    t.jsonb "tags", default: {}
    t.jsonb "metadata", default: {}
    t.integer "servers_count", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_groups_on_name"
    t.index ["slug"], name: "index_groups_on_slug", unique: true
  end

  create_table "hetzner_api_keys", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.text "api_token"
    t.string "project_id"
    t.boolean "enabled", default: true, null: false
    t.datetime "last_used_at"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["enabled"], name: "index_hetzner_api_keys_on_enabled"
  end

  create_table "scheduled_tasks", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.string "task_type", null: false
    t.jsonb "task_parameters", default: {}
    t.string "cron_schedule"
    t.datetime "next_run_at"
    t.datetime "last_run_at"
    t.boolean "enabled", default: true, null: false
    t.string "target_type", null: false
    t.uuid "target_id"
    t.text "salt_target"
    t.integer "timeout_seconds", default: 300
    t.boolean "run_async", default: true
    t.string "batch_size"
    t.integer "execution_count", default: 0
    t.integer "success_count", default: 0
    t.integer "failure_count", default: 0
    t.bigint "created_by_user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_user_id"], name: "index_scheduled_tasks_on_created_by_user_id"
    t.index ["enabled"], name: "index_scheduled_tasks_on_enabled"
    t.index ["next_run_at"], name: "index_scheduled_tasks_on_next_run_at"
    t.index ["target_id"], name: "index_scheduled_tasks_on_target_id"
    t.index ["target_type", "target_id"], name: "index_scheduled_tasks_on_target_type_and_target_id"
    t.index ["target_type"], name: "index_scheduled_tasks_on_target_type"
  end

  create_table "server_metrics", force: :cascade do |t|
    t.uuid "server_id", null: false
    t.float "cpu_percent"
    t.float "memory_percent"
    t.float "memory_used_gb"
    t.float "memory_total_gb"
    t.jsonb "disk_usage"
    t.jsonb "network_io"
    t.float "load_1m"
    t.float "load_5m"
    t.float "load_15m"
    t.integer "process_count"
    t.integer "tcp_connections"
    t.float "swap_percent"
    t.datetime "collected_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["collected_at"], name: "index_server_metrics_on_collected_at"
    t.index ["server_id"], name: "index_server_metrics_on_server_id"
  end

  create_table "servers", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "hostname"
    t.string "minion_id"
    t.string "ip_address"
    t.string "status"
    t.string "os_family"
    t.string "os_name"
    t.string "os_version"
    t.integer "cpu_cores"
    t.float "memory_gb"
    t.float "disk_gb"
    t.jsonb "grains"
    t.jsonb "latest_metrics"
    t.datetime "last_seen"
    t.datetime "last_heartbeat"
    t.string "environment"
    t.string "location"
    t.string "provider"
    t.jsonb "tags"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "group_id"
    t.decimal "latitude", precision: 10, scale: 6
    t.decimal "longitude", precision: 10, scale: 6
    t.uuid "hetzner_api_key_id"
    t.bigint "hetzner_server_id"
    t.boolean "enable_hetzner_snapshot", default: false, null: false
    t.string "hetzner_power_state"
    t.uuid "proxmox_api_key_id"
    t.string "proxmox_node"
    t.integer "proxmox_vmid"
    t.string "proxmox_type"
    t.index ["enable_hetzner_snapshot"], name: "index_servers_on_enable_hetzner_snapshot"
    t.index ["group_id", "status"], name: "index_servers_on_group_id_and_status"
    t.index ["group_id"], name: "index_servers_on_group_id"
    t.index ["hetzner_api_key_id"], name: "index_servers_on_hetzner_api_key_id"
    t.index ["hetzner_server_id"], name: "index_servers_on_hetzner_server_id"
    t.index ["hostname"], name: "index_servers_on_hostname", unique: true
    t.index ["minion_id"], name: "index_servers_on_minion_id", unique: true
    t.index ["proxmox_api_key_id"], name: "index_servers_on_proxmox_api_key_id"
  end

  create_table "task_executions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "scheduled_task_id", null: false
    t.string "status", default: "pending", null: false
    t.datetime "started_at"
    t.datetime "completed_at"
    t.integer "duration_seconds"
    t.jsonb "targets", default: []
    t.integer "success_count", default: 0
    t.integer "failure_count", default: 0
    t.text "summary"
    t.string "salt_job_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["scheduled_task_id", "started_at"], name: "index_task_executions_on_scheduled_task_id_and_started_at"
    t.index ["scheduled_task_id"], name: "index_task_executions_on_scheduled_task_id"
    t.index ["started_at"], name: "index_task_executions_on_started_at"
    t.index ["status"], name: "index_task_executions_on_status"
  end

  create_table "task_templates", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "category", null: false
    t.text "description"
    t.string "icon"
    t.string "task_type", null: false
    t.jsonb "default_parameters", default: {}
    t.text "command_template"
    t.boolean "requires_confirmation", default: false
    t.boolean "is_dangerous", default: false
    t.text "documentation_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category"], name: "index_task_templates_on_category"
    t.index ["name"], name: "index_task_templates_on_name", unique: true
    t.index ["task_type"], name: "index_task_templates_on_task_type"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.string "role", default: "viewer", null: false
    t.string "provider"
    t.string "uid"
    t.datetime "auth_time"
    t.string "session_id"
    t.datetime "token_expires_at"
    t.datetime "last_auth_check"
    t.string "encrypted_otp_secret"
    t.string "encrypted_otp_secret_iv"
    t.integer "consumed_timestep"
    t.boolean "otp_required_for_login", default: false
    t.text "otp_backup_codes", default: [], array: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["provider", "uid"], name: "index_users_on_provider_and_uid", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role"], name: "index_users_on_role"
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  add_foreign_key "backup_histories", "backup_configurations"
  add_foreign_key "commands", "servers"
  add_foreign_key "commands", "task_executions"
  add_foreign_key "scheduled_tasks", "users", column: "created_by_user_id"
  add_foreign_key "server_metrics", "servers"
  add_foreign_key "servers", "groups"
  add_foreign_key "servers", "hetzner_api_keys"
  add_foreign_key "servers", "proxmox_api_keys"
  add_foreign_key "task_executions", "scheduled_tasks"
end
