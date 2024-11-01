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

ActiveRecord::Schema[7.1].define(version: 2024_07_23_000308) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "accounts", force: :cascade do |t|
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "availabilities", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.text "name", default: "New User Availability", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_availabilities_on_user_id"
  end

  create_table "availability_schedules", force: :cascade do |t|
    t.bigint "availability_id", null: false
    t.bigint "schedule_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["availability_id"], name: "index_availability_schedules_on_availability_id"
    t.index ["schedule_id"], name: "index_availability_schedules_on_schedule_id"
  end

  create_table "game_proposals", force: :cascade do |t|
    t.bigint "group_id", null: false
    t.bigint "user_id", null: false
    t.bigint "game_id", null: false
    t.integer "yes_votes_count", default: 0, null: false
    t.integer "no_votes_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["game_id"], name: "index_game_proposals_on_game_id"
    t.index ["group_id"], name: "index_game_proposals_on_group_id"
    t.index ["user_id"], name: "index_game_proposals_on_user_id"
  end

  create_table "game_session_attendances", force: :cascade do |t|
    t.bigint "game_session_id", null: false
    t.bigint "user_id", null: false
    t.boolean "attending"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["game_session_id"], name: "index_game_session_attendances_on_game_session_id"
    t.index ["user_id"], name: "index_game_session_attendances_on_user_id"
  end

  create_table "game_sessions", force: :cascade do |t|
    t.bigint "game_proposal_id", null: false
    t.bigint "user_id", null: false
    t.datetime "date"
    t.interval "duration"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["game_proposal_id"], name: "index_game_sessions_on_game_proposal_id"
    t.index ["user_id"], name: "index_game_sessions_on_user_id"
  end

  create_table "games", force: :cascade do |t|
    t.bigint "igdb_id"
    t.text "name", null: false
    t.text "cover_image_url"
    t.text "platforms", default: [], null: false, array: true
    t.text "igdb_url"
    t.date "release_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["igdb_id"], name: "index_games_on_igdb_id", unique: true
    t.index ["name"], name: "index_games_on_name"
  end

  create_table "group_availabilities", force: :cascade do |t|
    t.bigint "availability_id", null: false
    t.bigint "group_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["availability_id"], name: "index_group_availabilities_on_availability_id"
    t.index ["group_id"], name: "index_group_availabilities_on_group_id"
    t.index ["user_id"], name: "index_group_availabilities_on_user_id"
  end

  create_table "group_memberships", force: :cascade do |t|
    t.bigint "group_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["group_id"], name: "index_group_memberships_on_group_id"
    t.index ["user_id"], name: "index_group_memberships_on_user_id"
  end

  create_table "groups", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "invites", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "group_id", null: false
    t.string "invite_token", null: false
    t.bigint "assigned_role_ids", default: [], null: false, array: true
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["group_id"], name: "index_invites_on_group_id"
    t.index ["invite_token"], name: "index_invites_on_invite_token", unique: true
    t.index ["user_id"], name: "index_invites_on_user_id"
  end

  create_table "proposal_availabilities", force: :cascade do |t|
    t.bigint "availability_id", null: false
    t.bigint "game_proposal_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["availability_id"], name: "index_proposal_availabilities_on_availability_id"
    t.index ["game_proposal_id"], name: "index_proposal_availabilities_on_game_proposal_id"
    t.index ["user_id"], name: "index_proposal_availabilities_on_user_id"
  end

  create_table "proposal_votes", force: :cascade do |t|
    t.bigint "game_proposal_id", null: false
    t.bigint "user_id", null: false
    t.boolean "yes_vote"
    t.text "comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["game_proposal_id"], name: "index_proposal_votes_on_game_proposal_id"
    t.index ["user_id"], name: "index_proposal_votes_on_user_id"
  end

  create_table "recovery_codes", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "code", null: false
    t.boolean "used", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_recovery_codes_on_user_id"
  end

  create_table "roles", force: :cascade do |t|
    t.string "name"
    t.string "resource_type"
    t.bigint "resource_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name", "resource_type", "resource_id"], name: "index_roles_on_name_and_resource_type_and_resource_id"
    t.index ["resource_type", "resource_id"], name: "index_roles_on_resource"
  end

  create_table "schedules", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.datetime "start_date"
    t.datetime "end_date"
    t.interval "duration"
    t.jsonb "schedule_pattern", default: {}, null: false
    t.text "name", default: "New Schedule", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["end_date"], name: "index_schedules_on_end_date"
    t.index ["start_date"], name: "index_schedules_on_start_date"
    t.index ["user_id"], name: "index_schedules_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "user_agent"
    t.string "ip_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "user_availabilities", force: :cascade do |t|
    t.bigint "availability_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["availability_id"], name: "index_user_availabilities_on_availability_id"
    t.index ["user_id"], name: "index_user_availabilities_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email"
    t.string "username", null: false
    t.string "password_digest", null: false
    t.string "timezone", default: "UTC", null: false
    t.boolean "verified", default: false, null: false
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_users_on_account_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  create_table "users_roles", id: false, force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "role_id"
    t.index ["role_id"], name: "index_users_roles_on_role_id"
    t.index ["user_id", "role_id"], name: "index_users_roles_on_user_id_and_role_id"
    t.index ["user_id"], name: "index_users_roles_on_user_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "availabilities", "users"
  add_foreign_key "availability_schedules", "availabilities"
  add_foreign_key "availability_schedules", "schedules"
  add_foreign_key "game_proposals", "games"
  add_foreign_key "game_proposals", "groups"
  add_foreign_key "game_proposals", "users"
  add_foreign_key "game_session_attendances", "game_sessions"
  add_foreign_key "game_session_attendances", "users"
  add_foreign_key "game_sessions", "game_proposals"
  add_foreign_key "game_sessions", "users"
  add_foreign_key "group_availabilities", "availabilities"
  add_foreign_key "group_availabilities", "groups"
  add_foreign_key "group_availabilities", "users"
  add_foreign_key "group_memberships", "groups"
  add_foreign_key "group_memberships", "users"
  add_foreign_key "invites", "groups"
  add_foreign_key "invites", "users"
  add_foreign_key "proposal_availabilities", "availabilities"
  add_foreign_key "proposal_availabilities", "game_proposals"
  add_foreign_key "proposal_availabilities", "users"
  add_foreign_key "proposal_votes", "game_proposals"
  add_foreign_key "proposal_votes", "users"
  add_foreign_key "recovery_codes", "users"
  add_foreign_key "schedules", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "user_availabilities", "availabilities"
  add_foreign_key "user_availabilities", "users"
  add_foreign_key "users", "accounts"
end
