class TrustedContact < ApplicationRecord
  belongs_to :member

  validates :name, :relationship, :access_level, presence: true
end
