class RenameCarePartnerAccountsToCarePartners < ActiveRecord::Migration[8.1]
  ASSOCIATED_TABLES = %i[
    care_partner_profiles
    care_partner_verification_documents
    care_partner_credentials
    care_partner_services
    service_offers
    service_assignments
    earnings_ledger_entries
    moderator_reviews
  ].freeze

  INDEX_RENAMES = {
    care_partners: {
      "index_care_partner_accounts_on_user_id" => "index_care_partners_on_user_id",
      "idx_on_application_status_availability_status_6d716cc234" => "index_care_partners_on_application_and_availability"
    },
    care_partner_profiles: {
      "index_care_partner_profiles_on_care_partner_account_id" => "index_care_partner_profiles_on_care_partner_id"
    },
    care_partner_verification_documents: {
      "index_care_partner_documents_on_account" => "index_care_partner_documents_on_partner",
      "index_care_partner_documents_on_account_and_status" => "index_care_partner_documents_on_partner_and_status"
    },
    care_partner_credentials: {
      "index_care_partner_credentials_on_care_partner_account_id" => "index_care_partner_credentials_on_care_partner_id",
      "index_care_partner_credentials_on_account_and_service" => "index_care_partner_credentials_on_partner_and_service"
    },
    care_partner_services: {
      "index_care_partner_services_on_care_partner_account_id" => "index_care_partner_services_on_care_partner_id",
      "index_care_partner_services_on_account_and_catalog" => "index_care_partner_services_on_partner_and_catalog"
    },
    service_offers: {
      "index_service_offers_on_care_partner_account_id" => "index_service_offers_on_care_partner_id",
      "index_service_offers_on_account_status_and_expiry" => "index_service_offers_on_partner_status_and_expiry",
      "idx_on_service_request_id_care_partner_account_id_d2bf398ad0" => "index_service_offers_on_request_and_partner"
    },
    service_assignments: {
      "index_service_assignments_on_care_partner_account_id" => "index_service_assignments_on_care_partner_id",
      "index_service_assignments_on_account_and_status" => "index_service_assignments_on_partner_and_status"
    },
    earnings_ledger_entries: {
      "index_earnings_ledger_entries_on_care_partner_account_id" => "index_earnings_ledger_entries_on_care_partner_id",
      "index_earnings_ledger_entries_on_account_and_status" => "index_earnings_ledger_entries_on_partner_and_status"
    },
    moderator_reviews: {
      "index_moderator_reviews_on_care_partner_account_id" => "index_moderator_reviews_on_care_partner_id",
      "index_moderator_reviews_on_account_and_created_at" => "index_moderator_reviews_on_partner_and_created_at"
    }
  }.freeze

  def up
    rename_table :care_partner_accounts, :care_partners
    ASSOCIATED_TABLES.each { |table| rename_column table, :care_partner_account_id, :care_partner_id }
    rename_indexes(INDEX_RENAMES)

    add_column :care_partners, :verification_status, :string, null: false, default: "pending"
    add_column :care_partners, :verified_at, :datetime
    add_index :care_partners, :verification_status

    execute <<~SQL.squish
      UPDATE care_partners
      SET verification_status = 'approved', verified_at = COALESCE(approved_at, updated_at)
      WHERE application_status IN ('approved', 'active')
    SQL
    execute <<~SQL.squish
      UPDATE care_partner_services
      SET status = 'active'
      FROM care_partners
      WHERE care_partner_services.care_partner_id = care_partners.id
        AND care_partners.verification_status = 'approved'
        AND care_partner_services.status = 'pending'
    SQL
  end

  def down
    remove_index :care_partners, :verification_status
    remove_column :care_partners, :verified_at
    remove_column :care_partners, :verification_status

    rename_indexes(INDEX_RENAMES.transform_values { |renames| renames.invert })
    ASSOCIATED_TABLES.each { |table| rename_column table, :care_partner_id, :care_partner_account_id }
    rename_table :care_partners, :care_partner_accounts
  end

  private

  def rename_indexes(index_renames)
    index_renames.each do |table, renames|
      renames.each do |from, to|
        rename_index table, from, to if connection.indexes(table).any? { |index| index.name == from }
      end
    end
  end
end
