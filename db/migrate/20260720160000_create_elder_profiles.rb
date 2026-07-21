class CreateElderProfiles < ActiveRecord::Migration[8.1]
  def change
    create_table :elder_profiles do |t|
      t.string :full_name, null: false
      t.string :phone_number
      t.string :preferred_language, null: false, default: "English"
      t.string :mobility_needs
      t.string :emergency_contact_name
      t.string :emergency_contact_phone
      t.jsonb :sharing_preferences, null: false, default: {}
      t.timestamps
    end
  end
end
