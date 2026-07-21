class TrustedContact < ApplicationRecord
  include BelongsToCareProfile

  validates :name, :relationship, :access_level, presence: true
end
