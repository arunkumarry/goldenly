class ActivateReadyCarePartners < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL.squish
      UPDATE care_partners
      SET payout_status = 'pending'
      WHERE payout_method_summary IS NOT NULL
        AND BTRIM(payout_method_summary) <> ''
        AND payout_status = 'not_started'
    SQL

    execute <<~SQL.squish
      UPDATE care_partners
      SET application_status = 'active', availability_status = 'available'
      WHERE application_status = 'approved'
        AND verification_status = 'approved'
        AND payout_method_summary IS NOT NULL
        AND BTRIM(payout_method_summary) <> ''
        AND EXISTS (
          SELECT 1
          FROM care_partner_services
          WHERE care_partner_services.care_partner_id = care_partners.id
            AND care_partner_services.status = 'active'
        )
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "Activation should not be rolled back because a Care Partner may have accepted work after becoming active."
  end
end
