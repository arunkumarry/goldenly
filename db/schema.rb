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

ActiveRecord::Schema[8.1].define(version: 2026_07_21_170000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "audit_events", force: :cascade do |t|
    t.string "action", null: false
    t.bigint "actor_user_id"
    t.bigint "care_profile_id"
    t.datetime "created_at", null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "occurred_at", null: false
    t.datetime "updated_at", null: false
    t.index ["actor_user_id"], name: "index_audit_events_on_actor_user_id"
    t.index ["care_profile_id", "occurred_at"], name: "index_audit_events_on_care_profile_id_and_occurred_at"
    t.index ["care_profile_id"], name: "index_audit_events_on_care_profile_id"
  end

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

  create_table "care_profile_links", force: :cascade do |t|
    t.bigint "care_profile_id", null: false
    t.datetime "created_at", null: false
    t.jsonb "permissions", default: {}, null: false
    t.string "relationship_to_person", default: "coordinator", null: false
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["care_profile_id"], name: "index_care_profile_links_on_care_profile_id"
    t.index ["user_id", "care_profile_id"], name: "index_care_profile_links_on_user_id_and_care_profile_id", unique: true
    t.index ["user_id"], name: "index_care_profile_links_on_user_id"
  end

  create_table "care_profiles", force: :cascade do |t|
    t.jsonb "accessibility_preferences", default: {}, null: false
    t.string "consent_basis"
    t.string "country"
    t.datetime "created_at", null: false
    t.string "emergency_contact_name"
    t.string "emergency_contact_phone"
    t.string "full_name", null: false
    t.string "location"
    t.string "mobility_needs"
    t.bigint "owner_user_id"
    t.string "phone_number"
    t.string "preferred_language", default: "English", null: false
    t.string "relationship_to_user", default: "self", null: false
    t.jsonb "sharing_preferences", default: {}, null: false
    t.string "state", default: "unclaimed", null: false
    t.datetime "updated_at", null: false
    t.index ["owner_user_id"], name: "index_care_profiles_on_owner_user_id"
  end

  create_table "consent_records", force: :cascade do |t|
    t.bigint "actor_user_id"
    t.datetime "captured_at", null: false
    t.bigint "care_profile_id", null: false
    t.datetime "created_at", null: false
    t.jsonb "permissions", default: {}, null: false
    t.string "purpose", null: false
    t.string "source", default: "web", null: false
    t.string "subject", null: false
    t.datetime "updated_at", null: false
    t.index ["actor_user_id"], name: "index_consent_records_on_actor_user_id"
    t.index ["care_profile_id"], name: "index_consent_records_on_care_profile_id"
  end

  create_table "email_verification_codes", force: :cascade do |t|
    t.integer "attempts_count", default: 0, null: false
    t.string "code_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "identifier", null: false
    t.datetime "updated_at", null: false
    t.datetime "used_at"
    t.index ["identifier"], name: "index_email_verification_codes_on_identifier", unique: true
  end

  create_table "emergency_alerts", force: :cascade do |t|
    t.bigint "care_profile_id", null: false
    t.datetime "confirmed_at"
    t.string "country"
    t.datetime "created_at", null: false
    t.string "emergency_number"
    t.string "location"
    t.text "message"
    t.boolean "share_location", default: false, null: false
    t.string "status", default: "awaiting_confirmation", null: false
    t.integer "trusted_contact_count", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["care_profile_id"], name: "index_emergency_alerts_on_care_profile_id"
  end

  create_table "profile_invitations", force: :cascade do |t|
    t.datetime "accepted_at"
    t.datetime "cancelled_at"
    t.bigint "care_profile_id", null: false
    t.string "contact_identifier", null: false
    t.datetime "created_at", null: false
    t.string "delivery_channel", default: "sms", null: false
    t.datetime "expires_at", null: false
    t.string "invitation_kind", default: "claim", null: false
    t.bigint "invited_by_id", null: false
    t.jsonb "permissions", default: {}, null: false
    t.string "token_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["care_profile_id", "contact_identifier"], name: "index_profile_invitations_on_profile_and_contact"
    t.index ["care_profile_id"], name: "index_profile_invitations_on_care_profile_id"
    t.index ["invited_by_id"], name: "index_profile_invitations_on_invited_by_id"
    t.index ["token_digest"], name: "index_profile_invitations_on_token_digest", unique: true
  end

  create_table "reminders", force: :cascade do |t|
    t.bigint "care_profile_id", null: false
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.boolean "created_by_ai", default: false, null: false
    t.string "recurrence"
    t.datetime "scheduled_for", null: false
    t.string "status", default: "pending", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["care_profile_id"], name: "index_reminders_on_care_profile_id"
  end

  create_table "service_catalogs", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.text "description", null: false
    t.integer "kind", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["kind"], name: "index_service_catalogs_on_kind", unique: true
  end

  create_table "service_requests", force: :cascade do |t|
    t.string "assigned_provider_name"
    t.string "assigned_provider_phone"
    t.bigint "care_profile_id", null: false
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.text "notes"
    t.datetime "preferred_time"
    t.bigint "service_catalog_id", null: false
    t.string "service_type", null: false
    t.string "status", default: "awaiting_confirmation", null: false
    t.datetime "updated_at", null: false
    t.index ["care_profile_id"], name: "index_service_requests_on_care_profile_id"
    t.index ["service_catalog_id"], name: "index_service_requests_on_service_catalog_id"
  end

  create_table "trusted_contacts", force: :cascade do |t|
    t.string "access_level", default: "Updates", null: false
    t.bigint "care_profile_id", null: false
    t.datetime "created_at", null: false
    t.string "email"
    t.string "name", null: false
    t.string "phone_number"
    t.string "relationship", null: false
    t.datetime "updated_at", null: false
    t.index ["care_profile_id"], name: "index_trusted_contacts_on_care_profile_id"
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

  add_foreign_key "audit_events", "care_profiles"
  add_foreign_key "audit_events", "users", column: "actor_user_id"
  add_foreign_key "authentication_tokens", "users"
  add_foreign_key "care_profile_links", "care_profiles"
  add_foreign_key "care_profile_links", "users"
  add_foreign_key "care_profiles", "users", column: "owner_user_id"
  add_foreign_key "consent_records", "care_profiles"
  add_foreign_key "consent_records", "users", column: "actor_user_id"
  add_foreign_key "emergency_alerts", "care_profiles"
  add_foreign_key "profile_invitations", "care_profiles"
  add_foreign_key "profile_invitations", "users", column: "invited_by_id"
  add_foreign_key "reminders", "care_profiles"
  add_foreign_key "service_requests", "care_profiles"
  add_foreign_key "service_requests", "service_catalogs"
  add_foreign_key "trusted_contacts", "care_profiles"
end
