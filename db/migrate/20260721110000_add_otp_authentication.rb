class AddOtpAuthentication < ActiveRecord::Migration[8.1]
  def change
    change_column_null :users, :email_address, true
    change_column_null :users, :password_digest, true
    add_column :users, :phone_number, :string
    add_column :users, :verified_at, :datetime
    add_index :users, :phone_number, unique: true

    create_table :authentication_tokens do |t|
      t.references :user, null: false, foreign_key: true
      t.string :token_digest, null: false
      t.datetime :expires_at, null: false
      t.datetime :revoked_at
      t.timestamps
    end
    add_index :authentication_tokens, :token_digest, unique: true
  end
end
