class DevicePushToken < ApplicationRecord
  belongs_to :user

  enum :platform, { ios: "ios", android: "android" }

  scope :active, -> { where(active: true) }

  validates :token, presence: true, uniqueness: true
end
