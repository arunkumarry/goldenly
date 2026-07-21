module BelongsToCareProfile
  extend ActiveSupport::Concern

  included do
    belongs_to :care_profile
    validates :care_profile, presence: true
  end
end
