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

ActiveRecord::Schema[8.1].define(version: 2026_07_23_093000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

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

  create_table "care_partner_credentials", force: :cascade do |t|
    t.bigint "care_partner_id", null: false
    t.datetime "created_at", null: false
    t.string "credential_reference"
    t.string "credential_type", null: false
    t.date "expires_on"
    t.string "file_reference"
    t.date "issued_on"
    t.string "issuer"
    t.text "review_note"
    t.bigint "service_catalog_id"
    t.datetime "updated_at", null: false
    t.string "verification_status", default: "pending", null: false
    t.index ["care_partner_id", "service_catalog_id"], name: "index_care_partner_credentials_on_partner_and_service"
    t.index ["care_partner_id"], name: "index_care_partner_credentials_on_care_partner_id"
    t.index ["service_catalog_id"], name: "index_care_partner_credentials_on_service_catalog_id"
  end

  create_table "care_partner_profiles", force: :cascade do |t|
    t.string "address"
    t.bigint "care_partner_id", null: false
    t.string "city"
    t.string "country"
    t.string "country_code", limit: 2
    t.datetime "created_at", null: false
    t.date "date_of_birth"
    t.string "display_name"
    t.string "emergency_contact_name"
    t.string "emergency_contact_phone"
    t.text "experience_summary"
    t.string "google_place_id"
    t.string "introduction_video_url"
    t.jsonb "languages", default: [], null: false
    t.decimal "latitude", precision: 10, scale: 6
    t.string "legal_name"
    t.boolean "location_consent", default: false, null: false
    t.decimal "longitude", precision: 10, scale: 6
    t.string "postal_code"
    t.string "profile_photo_url"
    t.string "region"
    t.datetime "updated_at", null: false
    t.index ["care_partner_id"], name: "index_care_partner_profiles_on_care_partner_id", unique: true
    t.index ["country_code", "city"], name: "index_care_partner_profiles_on_country_code_and_city"
    t.index ["google_place_id"], name: "index_care_partner_profiles_on_google_place_id"
  end

  create_table "care_partner_services", force: :cascade do |t|
    t.jsonb "availability", default: {}, null: false
    t.bigint "care_partner_id", null: false
    t.jsonb "coverage_place", default: {}, null: false
    t.datetime "created_at", null: false
    t.jsonb "languages", default: [], null: false
    t.integer "max_concurrent_visits", default: 1, null: false
    t.bigint "service_catalog_id", null: false
    t.jsonb "service_modes", default: ["in_person"], null: false
    t.jsonb "service_zones", default: [], null: false
    t.string "status", default: "pending", null: false
    t.integer "travel_radius_km"
    t.datetime "updated_at", null: false
    t.index ["care_partner_id", "service_catalog_id"], name: "index_care_partner_services_on_partner_and_catalog", unique: true
    t.index ["care_partner_id"], name: "index_care_partner_services_on_care_partner_id"
    t.index ["service_catalog_id", "status"], name: "index_care_partner_services_on_catalog_and_status"
    t.index ["service_catalog_id"], name: "index_care_partner_services_on_service_catalog_id"
  end

  create_table "care_partner_verification_documents", force: :cascade do |t|
    t.bigint "care_partner_id", null: false
    t.string "country_code", limit: 2
    t.datetime "created_at", null: false
    t.string "document_type", null: false
    t.date "expires_on"
    t.string "file_reference"
    t.string "redacted_reference"
    t.text "review_note"
    t.datetime "updated_at", null: false
    t.string "verification_status", default: "pending", null: false
    t.index ["care_partner_id", "verification_status"], name: "index_care_partner_documents_on_partner_and_status"
    t.index ["care_partner_id"], name: "index_care_partner_documents_on_partner"
  end

  create_table "care_partners", force: :cascade do |t|
    t.string "application_status", default: "draft", null: false
    t.datetime "approved_at"
    t.string "availability_status", default: "paused", null: false
    t.datetime "code_of_conduct_accepted_at"
    t.datetime "created_at", null: false
    t.integer "onboarding_step", default: 1, null: false
    t.string "payout_method_summary"
    t.string "payout_status", default: "not_started", null: false
    t.datetime "privacy_accepted_at"
    t.text "review_note"
    t.datetime "service_standards_accepted_at"
    t.datetime "submitted_at"
    t.datetime "suspended_at"
    t.datetime "terms_accepted_at"
    t.string "terms_version"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.string "verification_status", default: "pending", null: false
    t.datetime "verified_at"
    t.index ["application_status", "availability_status"], name: "idx_on_application_status_availability_status_0e2520faba"
    t.index ["user_id"], name: "index_care_partners_on_user_id", unique: true
    t.index ["verification_status"], name: "index_care_partners_on_verification_status"
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
    t.string "address"
    t.string "city"
    t.string "consent_basis"
    t.string "country"
    t.string "country_code", limit: 2
    t.datetime "created_at", null: false
    t.string "emergency_contact_name"
    t.string "emergency_contact_phone"
    t.string "full_name", null: false
    t.string "google_place_id"
    t.decimal "latitude", precision: 10, scale: 6
    t.string "location"
    t.decimal "longitude", precision: 10, scale: 6
    t.string "mobility_needs"
    t.bigint "owner_user_id"
    t.string "phone_number"
    t.string "postal_code"
    t.string "preferred_language", default: "English", null: false
    t.string "region"
    t.string "relationship_to_user", default: "self", null: false
    t.jsonb "sharing_preferences", default: {}, null: false
    t.string "state", default: "unclaimed", null: false
    t.datetime "updated_at", null: false
    t.index ["google_place_id"], name: "index_care_profiles_on_google_place_id"
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

  create_table "device_push_tokens", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "last_seen_at", null: false
    t.string "platform", null: false
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["token"], name: "index_device_push_tokens_on_token", unique: true
    t.index ["user_id", "active"], name: "index_device_push_tokens_on_user_id_and_active"
    t.index ["user_id"], name: "index_device_push_tokens_on_user_id"
  end

  create_table "earnings_ledger_entries", force: :cascade do |t|
    t.integer "adjustment_cents", default: 0, null: false
    t.datetime "available_at"
    t.bigint "care_partner_id", null: false
    t.datetime "created_at", null: false
    t.string "currency", default: "USD", null: false
    t.integer "goldenly_fee_cents", default: 0, null: false
    t.integer "net_payout_cents", default: 0, null: false
    t.datetime "paid_at"
    t.string "payout_reference"
    t.text "review_note"
    t.bigint "service_assignment_id", null: false
    t.integer "service_value_cents", default: 0, null: false
    t.string "status", default: "estimated", null: false
    t.datetime "updated_at", null: false
    t.index ["care_partner_id", "status"], name: "index_earnings_ledger_entries_on_partner_and_status"
    t.index ["care_partner_id"], name: "index_earnings_ledger_entries_on_care_partner_id"
    t.index ["service_assignment_id"], name: "index_earnings_ledger_entries_on_service_assignment_id", unique: true
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

  create_table "moderator_reviews", force: :cascade do |t|
    t.jsonb "ai_assistance", default: {}, null: false
    t.bigint "care_partner_id", null: false
    t.datetime "created_at", null: false
    t.string "decision", null: false
    t.text "reason", null: false
    t.jsonb "requested_sections", default: [], null: false
    t.bigint "reviewer_id", null: false
    t.datetime "updated_at", null: false
    t.index ["care_partner_id", "created_at"], name: "index_moderator_reviews_on_partner_and_created_at"
    t.index ["care_partner_id"], name: "index_moderator_reviews_on_care_partner_id"
    t.index ["reviewer_id"], name: "index_moderator_reviews_on_reviewer_id"
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

  create_table "service_assignments", force: :cascade do |t|
    t.datetime "accepted_at", null: false
    t.string "cancellation_reason"
    t.bigint "care_partner_id", null: false
    t.datetime "checked_in_at"
    t.datetime "completed_at"
    t.string "completion_outcome"
    t.boolean "contact_released", default: false, null: false
    t.datetime "created_at", null: false
    t.string "escalation_reason"
    t.string "member_confirmation_code_digest"
    t.string "member_confirmation_code_hint"
    t.datetime "member_confirmation_expires_at"
    t.datetime "member_confirmed_at"
    t.bigint "service_request_id", null: false
    t.datetime "started_at"
    t.string "status", default: "assigned", null: false
    t.datetime "updated_at", null: false
    t.index ["care_partner_id", "status"], name: "index_service_assignments_on_partner_and_status"
    t.index ["care_partner_id"], name: "index_service_assignments_on_care_partner_id"
    t.index ["service_request_id"], name: "index_service_assignments_on_service_request_id", unique: true
  end

  create_table "service_catalogs", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.boolean "clinical", default: false, null: false
    t.datetime "created_at", null: false
    t.string "currency", default: "USD", null: false
    t.text "description", null: false
    t.integer "kind", null: false
    t.integer "member_price_cents", default: 0, null: false
    t.string "name", null: false
    t.integer "partner_earning_cents", default: 0, null: false
    t.boolean "requires_professional_credential", default: false, null: false
    t.boolean "subscription_eligible", default: false, null: false
    t.datetime "updated_at", null: false
    t.index ["kind"], name: "index_service_catalogs_on_kind", unique: true
  end

  create_table "service_offers", force: :cascade do |t|
    t.bigint "care_partner_id", null: false
    t.datetime "created_at", null: false
    t.jsonb "eligibility_snapshot", default: {}, null: false
    t.datetime "expires_at"
    t.datetime "offered_at", null: false
    t.datetime "responded_at"
    t.bigint "service_request_id", null: false
    t.string "status", default: "offered", null: false
    t.datetime "updated_at", null: false
    t.index ["care_partner_id", "status", "expires_at"], name: "index_service_offers_on_partner_status_and_expiry"
    t.index ["care_partner_id"], name: "index_service_offers_on_care_partner_id"
    t.index ["service_request_id", "care_partner_id"], name: "index_service_offers_on_service_request_id_and_care_partner_id", unique: true
    t.index ["service_request_id"], name: "index_service_offers_on_service_request_id"
  end

  create_table "service_requests", force: :cascade do |t|
    t.string "assigned_provider_name"
    t.string "assigned_provider_phone"
    t.bigint "care_profile_id", null: false
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.text "notes"
    t.datetime "offers_published_at"
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
    t.string "address"
    t.string "city"
    t.string "country"
    t.string "country_code", limit: 2
    t.datetime "created_at", null: false
    t.string "email_address"
    t.string "full_name", null: false
    t.string "google_place_id"
    t.decimal "latitude", precision: 10, scale: 6
    t.string "location"
    t.decimal "longitude", precision: 10, scale: 6
    t.string "password_digest"
    t.string "phone_number"
    t.string "platform_role", default: "member", null: false
    t.string "postal_code"
    t.string "region"
    t.datetime "updated_at", null: false
    t.datetime "verified_at"
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["google_place_id"], name: "index_users_on_google_place_id"
    t.index ["phone_number"], name: "index_users_on_phone_number", unique: true
    t.index ["platform_role"], name: "index_users_on_platform_role"
  end

  create_table "visit_submissions", force: :cascade do |t|
    t.jsonb "checklist", default: {}, null: false
    t.datetime "created_at", null: false
    t.string "escalation_status", default: "none", null: false
    t.jsonb "evidence", default: [], null: false
    t.text "follow_up_needed"
    t.text "notes"
    t.bigint "service_assignment_id", null: false
    t.datetime "submitted_at", null: false
    t.datetime "updated_at", null: false
    t.index ["service_assignment_id"], name: "index_visit_submissions_on_service_assignment_id", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "audit_events", "care_profiles"
  add_foreign_key "audit_events", "users", column: "actor_user_id"
  add_foreign_key "authentication_tokens", "users"
  add_foreign_key "care_partner_credentials", "care_partners"
  add_foreign_key "care_partner_credentials", "service_catalogs"
  add_foreign_key "care_partner_profiles", "care_partners"
  add_foreign_key "care_partner_services", "care_partners"
  add_foreign_key "care_partner_services", "service_catalogs"
  add_foreign_key "care_partner_verification_documents", "care_partners"
  add_foreign_key "care_partners", "users"
  add_foreign_key "care_profile_links", "care_profiles"
  add_foreign_key "care_profile_links", "users"
  add_foreign_key "care_profiles", "users", column: "owner_user_id"
  add_foreign_key "consent_records", "care_profiles"
  add_foreign_key "consent_records", "users", column: "actor_user_id"
  add_foreign_key "device_push_tokens", "users"
  add_foreign_key "earnings_ledger_entries", "care_partners"
  add_foreign_key "earnings_ledger_entries", "service_assignments"
  add_foreign_key "emergency_alerts", "care_profiles"
  add_foreign_key "moderator_reviews", "care_partners"
  add_foreign_key "moderator_reviews", "users", column: "reviewer_id"
  add_foreign_key "profile_invitations", "care_profiles"
  add_foreign_key "profile_invitations", "users", column: "invited_by_id"
  add_foreign_key "reminders", "care_profiles"
  add_foreign_key "service_assignments", "care_partners"
  add_foreign_key "service_assignments", "service_requests"
  add_foreign_key "service_offers", "care_partners"
  add_foreign_key "service_offers", "service_requests"
  add_foreign_key "service_requests", "care_profiles"
  add_foreign_key "service_requests", "service_catalogs"
  add_foreign_key "trusted_contacts", "care_profiles"
  add_foreign_key "visit_submissions", "service_assignments"
end
