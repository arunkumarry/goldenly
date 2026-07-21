class CreateEmailVerificationCodes < ActiveRecord::Migration[8.1]
  def change
    create_table :email_verification_codes do |t|
      t.string :identifier, null: false
      t.string :code_digest, null: false
      t.datetime :expires_at, null: false
      t.datetime :used_at
      t.integer :attempts_count, null: false, default: 0

      t.timestamps
    end

    add_index :email_verification_codes, :identifier, unique: true
  end
end
