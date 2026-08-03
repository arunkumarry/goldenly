class CreateHospitalAndSosAuditRecords < ActiveRecord::Migration[8.1]
  def change
    execute <<~SQL.squish
      UPDATE care_profile_links
      SET permissions = COALESCE(permissions, '{}'::jsonb) || '{"location_access":"manage"}'::jsonb
      WHERE NOT (COALESCE(permissions, '{}'::jsonb) ? 'location_access')
    SQL

    create_table :hospital_search_events do |t|
      t.references :actor_user, foreign_key: { to_table: :users }
      t.references :care_profile, null: false, foreign_key: true
      t.string :location_source, null: false
      t.string :consent_basis, null: false
      t.string :country, null: false
      t.datetime :searched_at, null: false
      t.integer :result_count, null: false, default: 0
      t.string :status, null: false
      t.timestamps
    end

    add_index :hospital_search_events, [ :care_profile_id, :searched_at ]

    create_table :hospital_place_actions do |t|
      t.references :hospital_search_event, null: false, foreign_key: true
      t.string :google_place_id, null: false
      t.string :action_type, null: false
      t.datetime :initiated_at, null: false
      t.timestamps
    end

    create_table :care_profile_location_preferences do |t|
      t.references :care_profile, null: false, foreign_key: true, index: { unique: true }
      t.string :location_sharing_preference, null: false, default: "ask_each_time"
      t.string :preferred_hospital_place_id
      t.datetime :preferred_hospital_selected_at
      t.timestamps
    end

    create_table :sos_alert_deliveries do |t|
      t.references :emergency_alert, null: false, foreign_key: true
      t.references :recipient_user, foreign_key: { to_table: :users }
      t.string :recipient_label, null: false
      t.string :channel, null: false
      t.string :status, null: false
      t.string :consent_basis, null: false
      t.boolean :location_shared, null: false, default: false
      t.jsonb :metadata, null: false, default: {}
      t.datetime :delivered_at
      t.timestamps
    end
  end
end
