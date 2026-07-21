class CreateTrustedContacts < ActiveRecord::Migration[8.1]
  def change
    create_table :trusted_contacts do |t|
      t.references :member, null: false, foreign_key: true
      t.string :name, null: false
      t.string :relationship, null: false
      t.string :phone_number
      t.string :email
      t.string :access_level, null: false, default: "Updates"
      t.timestamps
    end
  end
end
