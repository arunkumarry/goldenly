class Reminder < ApplicationRecord
  include BelongsToCareProfile

  validates :title, :scheduled_for, presence: true
end
