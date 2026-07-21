class CreateUsersAndAssignMembers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :full_name, null: false
      t.string :email_address, null: false
      t.string :password_digest, null: false
      t.timestamps
    end
    add_index :users, :email_address, unique: true

    add_reference :members, :user, foreign_key: true
    add_column :members, :relationship_to_user, :string, null: false, default: "self"
  end
end
