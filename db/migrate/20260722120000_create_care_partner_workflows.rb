class CreateCarePartnerWorkflows < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :platform_role, :string, null: false, default: "member"
    add_index :users, :platform_role

    add_column :service_catalogs, :clinical, :boolean, null: false, default: false
    add_column :service_catalogs, :requires_professional_credential, :boolean, null: false, default: false
    add_column :service_catalogs, :member_price_cents, :integer, null: false, default: 0
    add_column :service_catalogs, :partner_earning_cents, :integer, null: false, default: 0
    add_column :service_catalogs, :currency, :string, null: false, default: "USD"
    add_column :service_catalogs, :subscription_eligible, :boolean, null: false, default: false

    add_column :service_requests, :offers_published_at, :datetime

    create_table :care_partner_accounts do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.string :application_status, null: false, default: "draft"
      t.string :availability_status, null: false, default: "paused"
      t.string :payout_status, null: false, default: "not_started"
      t.integer :onboarding_step, null: false, default: 1
      t.string :terms_version
      t.datetime :terms_accepted_at
      t.datetime :privacy_accepted_at
      t.datetime :code_of_conduct_accepted_at
      t.datetime :service_standards_accepted_at
      t.string :payout_method_summary
      t.text :review_note
      t.datetime :submitted_at
      t.datetime :approved_at
      t.datetime :suspended_at
      t.timestamps
    end
    add_index :care_partner_accounts, [ :application_status, :availability_status ]

    create_table :care_partner_profiles do |t|
      t.references :care_partner_account, null: false, foreign_key: true, index: { unique: true }
      t.string :legal_name
      t.string :display_name
      t.date :date_of_birth
      t.string :profile_photo_url
      t.string :address
      t.string :city
      t.string :region
      t.string :country
      t.string :country_code, limit: 2
      t.string :postal_code
      t.string :google_place_id
      t.decimal :latitude, precision: 10, scale: 6
      t.decimal :longitude, precision: 10, scale: 6
      t.jsonb :languages, null: false, default: []
      t.text :experience_summary
      t.string :introduction_video_url
      t.string :emergency_contact_name
      t.string :emergency_contact_phone
      t.boolean :location_consent, null: false, default: false
      t.timestamps
    end
    add_index :care_partner_profiles, :google_place_id
    add_index :care_partner_profiles, [ :country_code, :city ]

    create_table :care_partner_verification_documents do |t|
      t.references :care_partner_account, null: false, foreign_key: true, index: { name: "index_care_partner_documents_on_account" }
      t.string :document_type, null: false
      t.string :country_code, limit: 2
      t.string :redacted_reference
      t.string :file_reference
      t.string :verification_status, null: false, default: "pending"
      t.date :expires_on
      t.text :review_note
      t.timestamps
    end
    add_index :care_partner_verification_documents, [ :care_partner_account_id, :verification_status ], name: "index_care_partner_documents_on_account_and_status"

    create_table :care_partner_credentials do |t|
      t.references :care_partner_account, null: false, foreign_key: true
      t.references :service_catalog, foreign_key: true
      t.string :credential_type, null: false
      t.string :issuer
      t.string :credential_reference
      t.string :file_reference
      t.string :verification_status, null: false, default: "pending"
      t.date :issued_on
      t.date :expires_on
      t.text :review_note
      t.timestamps
    end
    add_index :care_partner_credentials, [ :care_partner_account_id, :service_catalog_id ], name: "index_care_partner_credentials_on_account_and_service"

    create_table :care_partner_services do |t|
      t.references :care_partner_account, null: false, foreign_key: true
      t.references :service_catalog, null: false, foreign_key: true
      t.string :status, null: false, default: "pending"
      t.jsonb :service_zones, null: false, default: []
      t.jsonb :languages, null: false, default: []
      t.jsonb :service_modes, null: false, default: [ "in_person" ]
      t.jsonb :availability, null: false, default: {}
      t.integer :travel_radius_km
      t.integer :max_concurrent_visits, null: false, default: 1
      t.timestamps
    end
    add_index :care_partner_services, [ :care_partner_account_id, :service_catalog_id ], unique: true, name: "index_care_partner_services_on_account_and_catalog"
    add_index :care_partner_services, [ :service_catalog_id, :status ], name: "index_care_partner_services_on_catalog_and_status"

    create_table :service_offers do |t|
      t.references :service_request, null: false, foreign_key: true
      t.references :care_partner_account, null: false, foreign_key: true
      t.string :status, null: false, default: "offered"
      t.datetime :offered_at, null: false
      t.datetime :expires_at
      t.datetime :responded_at
      t.jsonb :eligibility_snapshot, null: false, default: {}
      t.timestamps
    end
    add_index :service_offers, [ :service_request_id, :care_partner_account_id ], unique: true
    add_index :service_offers, [ :care_partner_account_id, :status, :expires_at ], name: "index_service_offers_on_account_status_and_expiry"

    create_table :service_assignments do |t|
      t.references :service_request, null: false, foreign_key: true, index: { unique: true }
      t.references :care_partner_account, null: false, foreign_key: true
      t.string :status, null: false, default: "assigned"
      t.datetime :accepted_at, null: false
      t.datetime :checked_in_at
      t.datetime :started_at
      t.datetime :completed_at
      t.datetime :member_confirmed_at
      t.datetime :member_confirmation_expires_at
      t.string :member_confirmation_code_digest
      t.string :member_confirmation_code_hint
      t.string :completion_outcome
      t.string :cancellation_reason
      t.string :escalation_reason
      t.boolean :contact_released, null: false, default: false
      t.timestamps
    end
    add_index :service_assignments, [ :care_partner_account_id, :status ], name: "index_service_assignments_on_account_and_status"

    create_table :visit_submissions do |t|
      t.references :service_assignment, null: false, foreign_key: true, index: { unique: true }
      t.jsonb :checklist, null: false, default: {}
      t.text :notes
      t.jsonb :evidence, null: false, default: []
      t.string :escalation_status, null: false, default: "none"
      t.text :follow_up_needed
      t.datetime :submitted_at, null: false
      t.timestamps
    end

    create_table :earnings_ledger_entries do |t|
      t.references :care_partner_account, null: false, foreign_key: true
      t.references :service_assignment, null: false, foreign_key: true, index: { unique: true }
      t.string :currency, null: false, default: "USD"
      t.integer :service_value_cents, null: false, default: 0
      t.integer :goldenly_fee_cents, null: false, default: 0
      t.integer :adjustment_cents, null: false, default: 0
      t.integer :net_payout_cents, null: false, default: 0
      t.string :status, null: false, default: "estimated"
      t.string :payout_reference
      t.text :review_note
      t.datetime :available_at
      t.datetime :paid_at
      t.timestamps
    end
    add_index :earnings_ledger_entries, [ :care_partner_account_id, :status ], name: "index_earnings_ledger_entries_on_account_and_status"

    create_table :moderator_reviews do |t|
      t.references :care_partner_account, null: false, foreign_key: true
      t.references :reviewer, null: false, foreign_key: { to_table: :users }
      t.string :decision, null: false
      t.text :reason, null: false
      t.jsonb :requested_sections, null: false, default: []
      t.jsonb :ai_assistance, null: false, default: {}
      t.timestamps
    end
    add_index :moderator_reviews, [ :care_partner_account_id, :created_at ], name: "index_moderator_reviews_on_account_and_created_at"

    reversible do |direction|
      direction.up do
        execute <<~SQL.squish
          UPDATE service_catalogs
          SET clinical = kind IN (0, 6),
              requires_professional_credential = kind IN (0, 6),
              subscription_eligible = kind IN (1, 4, 5),
              member_price_cents = CASE kind
                WHEN 0 THEN 6000 WHEN 1 THEN 2500 WHEN 2 THEN 1800
                WHEN 3 THEN 2200 WHEN 4 THEN 2000 WHEN 5 THEN 1500
                WHEN 6 THEN 4500 ELSE 0 END,
              partner_earning_cents = CASE kind
                WHEN 0 THEN 4200 WHEN 1 THEN 1750 WHEN 2 THEN 1260
                WHEN 3 THEN 1540 WHEN 4 THEN 1400 WHEN 5 THEN 1050
                WHEN 6 THEN 3150 ELSE 0 END
        SQL
      end
    end
  end
end
