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

ActiveRecord::Schema[8.1].define(version: 2026_07_21_110000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "authentication_tokens", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.datetime "revoked_at"
    t.string "token_digest", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["token_digest"], name: "index_authentication_tokens_on_token_digest", unique: true
    t.index ["user_id"], name: "index_authentication_tokens_on_user_id"
  end

  create_table "members", force: :cascade do |t|
    t.string "country"
    t.datetime "created_at", null: false
    t.string "emergency_contact_name"
    t.string "emergency_contact_phone"
    t.string "full_name", null: false
    t.string "location"
    t.string "mobility_needs"
    t.string "phone_number"
    t.string "preferred_language", default: "English", null: false
    t.string "relationship_to_user", default: "self", null: false
    t.jsonb "sharing_preferences", default: {}, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["user_id"], name: "index_members_on_user_id"
  end

  create_table "reminders", force: :cascade do |t|
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.boolean "created_by_ai", default: false, null: false
    t.bigint "member_id", null: false
    t.string "recurrence"
    t.datetime "scheduled_for", null: false
    t.string "status", default: "pending", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["member_id"], name: "index_reminders_on_member_id"
  end

  create_table "service_requests", force: :cascade do |t|
    t.string "assigned_provider_name"
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.bigint "member_id", null: false
    t.text "notes"
    t.datetime "preferred_time"
    t.string "service_type", null: false
    t.string "status", default: "awaiting_confirmation", null: false
    t.datetime "updated_at", null: false
    t.index ["member_id"], name: "index_service_requests_on_member_id"
  end

  create_table "trusted_contacts", force: :cascade do |t|
    t.string "access_level", default: "Updates", null: false
    t.datetime "created_at", null: false
    t.string "email"
    t.bigint "member_id", null: false
    t.string "name", null: false
    t.string "phone_number"
    t.string "relationship", null: false
    t.datetime "updated_at", null: false
    t.index ["member_id"], name: "index_trusted_contacts_on_member_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "country"
    t.datetime "created_at", null: false
    t.string "email_address"
    t.string "full_name", null: false
    t.string "location"
    t.string "password_digest"
    t.string "phone_number"
    t.datetime "updated_at", null: false
    t.datetime "verified_at"
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["phone_number"], name: "index_users_on_phone_number", unique: true
  end

  add_foreign_key "authentication_tokens", "users"
  add_foreign_key "members", "users"
  add_foreign_key "reminders", "members"
  add_foreign_key "service_requests", "members"
  add_foreign_key "trusted_contacts", "members"
end
