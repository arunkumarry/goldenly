class AddCoveragePlaceToCarePartnerServices < ActiveRecord::Migration[8.1]
  def change
    add_column :care_partner_services, :coverage_place, :jsonb, default: {}, null: false
  end
end
