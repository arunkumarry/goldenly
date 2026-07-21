class CreateServiceRequests < ActiveRecord::Migration[8.1]
  def change
    create_table :service_requests do |t|
      t.references :elder_profile, null: false, foreign_key: true
      t.string :service_type, null: false
      t.string :status, null: false, default: "awaiting_confirmation"
      t.datetime :preferred_time
      t.text :notes
      t.string :assigned_provider_name
      t.datetime :confirmed_at
      t.timestamps
    end
  end
end
