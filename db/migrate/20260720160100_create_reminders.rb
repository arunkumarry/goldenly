class CreateReminders < ActiveRecord::Migration[8.1]
  def change
    create_table :reminders do |t|
      t.references :elder_profile, null: false, foreign_key: true
      t.string :title, null: false
      t.datetime :scheduled_for, null: false
      t.string :recurrence
      t.string :status, null: false, default: "pending"
      t.boolean :created_by_ai, null: false, default: false
      t.datetime :confirmed_at
      t.timestamps
    end
  end
end
