class CreateEmergencyAlertsAndProviderPhoneNumbers < ActiveRecord::Migration[8.1]
  def change
    add_column :service_requests, :assigned_provider_phone, :string

    create_table :emergency_alerts do |t|
      t.references :member, null: false, foreign_key: true
      t.string :status, null: false, default: "awaiting_confirmation"
      t.text :message
      t.boolean :share_location, null: false, default: false
      t.string :location
      t.string :country
      t.string :emergency_number
      t.integer :trusted_contact_count, null: false, default: 0
      t.datetime :confirmed_at

      t.timestamps
    end
  end
end
