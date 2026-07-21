class CreateDevicePushTokens < ActiveRecord::Migration[8.1]
  def change
    create_table :device_push_tokens do |t|
      t.references :user, null: false, foreign_key: true
      t.string :token, null: false
      t.string :platform, null: false
      t.boolean :active, null: false, default: true
      t.datetime :last_seen_at, null: false

      t.timestamps
    end

    add_index :device_push_tokens, :token, unique: true
    add_index :device_push_tokens, [ :user_id, :active ]
  end
end
