class IntroduceCareProfilesAndAccessControl < ActiveRecord::Migration[8.1]
  class LegacyCareProfile < ActiveRecord::Base
    self.table_name = "care_profiles"
  end

  class LegacyUser < ActiveRecord::Base
    self.table_name = "users"
  end

  def up
    rename_table :members, :care_profiles
    %i[reminders service_requests trusted_contacts emergency_alerts].each do |table|
      rename_column table, :member_id, :care_profile_id
    end

    add_reference :care_profiles, :owner_user, foreign_key: { to_table: :users }
    add_column :care_profiles, :state, :string, null: false, default: "unclaimed"
    add_column :care_profiles, :consent_basis, :string
    add_column :care_profiles, :accessibility_preferences, :jsonb, null: false, default: {}

    create_table :care_profile_links do |t|
      t.references :user, null: false, foreign_key: true
      t.references :care_profile, null: false, foreign_key: true
      t.string :relationship_to_person, null: false, default: "coordinator"
      t.string :status, null: false, default: "active"
      t.jsonb :permissions, null: false, default: {}
      t.timestamps
    end
    add_index :care_profile_links, %i[user_id care_profile_id], unique: true

    create_table :profile_invitations do |t|
      t.references :care_profile, null: false, foreign_key: true
      t.references :invited_by, null: false, foreign_key: { to_table: :users }
      t.string :contact_identifier, null: false
      t.string :delivery_channel, null: false, default: "sms"
      t.string :invitation_kind, null: false, default: "claim"
      t.jsonb :permissions, null: false, default: {}
      t.string :token_digest, null: false
      t.datetime :expires_at, null: false
      t.datetime :accepted_at
      t.datetime :cancelled_at
      t.timestamps
    end
    add_index :profile_invitations, :token_digest, unique: true
    add_index :profile_invitations, %i[care_profile_id contact_identifier], name: "index_profile_invitations_on_profile_and_contact"

    create_table :consent_records do |t|
      t.references :care_profile, null: false, foreign_key: true
      t.references :actor_user, foreign_key: { to_table: :users }
      t.string :subject, null: false
      t.string :purpose, null: false
      t.jsonb :permissions, null: false, default: {}
      t.string :source, null: false, default: "web"
      t.datetime :captured_at, null: false
      t.timestamps
    end

    create_table :audit_events do |t|
      t.references :actor_user, foreign_key: { to_table: :users }
      t.references :care_profile, foreign_key: true
      t.string :action, null: false
      t.jsonb :metadata, null: false, default: {}
      t.datetime :occurred_at, null: false
      t.timestamps
    end
    add_index :audit_events, %i[care_profile_id occurred_at]

    migrate_existing_profiles
    remove_reference :care_profiles, :user, foreign_key: true
  end

  def down
    add_reference :care_profiles, :user, foreign_key: true
    LegacyCareProfile.reset_column_information
    execute <<~SQL.squish
      UPDATE care_profiles
      SET user_id = owner_user_id
      WHERE owner_user_id IS NOT NULL
    SQL

    drop_table :audit_events
    drop_table :consent_records
    drop_table :profile_invitations
    drop_table :care_profile_links
    remove_column :care_profiles, :accessibility_preferences
    remove_column :care_profiles, :consent_basis
    remove_column :care_profiles, :state
    remove_reference :care_profiles, :owner_user, foreign_key: { to_table: :users }

    %i[reminders service_requests trusted_contacts emergency_alerts].each do |table|
      rename_column table, :care_profile_id, :member_id
    end
    rename_table :care_profiles, :members
  end

  private

  def migrate_existing_profiles
    LegacyCareProfile.reset_column_information
    LegacyUser.reset_column_information

    LegacyCareProfile.where.not(user_id: nil).find_each do |profile|
      user_id = profile.read_attribute(:user_id)
      relationship = profile.read_attribute(:relationship_to_user).presence || "coordinator"
      owner = relationship == "self" ? user_id : nil
      profile.update_columns(owner_user_id: owner, state: owner ? "claimed" : "unclaimed")

      execute <<~SQL.squish
        INSERT INTO care_profile_links (user_id, care_profile_id, relationship_to_person, status, permissions, created_at, updated_at)
        VALUES (#{user_id}, #{profile.id}, #{connection.quote(relationship)}, 'active', #{connection.quote(CareProfilePermissions.full_access.to_json)}::jsonb, NOW(), NOW())
        ON CONFLICT (user_id, care_profile_id) DO NOTHING
      SQL
    end
  end
end
