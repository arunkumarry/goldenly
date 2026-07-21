class Reminder < ApplicationRecord
  belongs_to :member

  validates :title, :scheduled_for, presence: true
end
