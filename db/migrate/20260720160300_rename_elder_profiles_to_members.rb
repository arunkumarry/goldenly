class RenameElderProfilesToMembers < ActiveRecord::Migration[8.1]
  def change
    rename_table :elder_profiles, :members
    rename_column :reminders, :elder_profile_id, :member_id
    rename_column :service_requests, :elder_profile_id, :member_id
  end
end
