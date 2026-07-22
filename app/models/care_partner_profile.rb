class CarePartnerProfile < ApplicationRecord
  PROFILE_PHOTO_CONTENT_TYPES = %w[image/jpeg image/png image/webp].freeze
  PROFILE_PHOTO_MAX_SIZE = 5.megabytes

  belongs_to :care_partner_account
  has_one_attached :profile_photo

  normalizes :country_code, with: ->(value) { value&.upcase&.strip }
  normalizes :languages, with: ->(values) { Array(values).map { |value| value.to_s.strip }.reject(&:blank?).uniq }

  validates :country_code, length: { is: 2 }, allow_blank: true
  validate :languages_are_strings
  validate :profile_photo_is_safe

  def broad_location
    [ city, region, country ].compact_blank.join(", ")
  end

  private

  def languages_are_strings
    errors.add(:languages, "must be a list") unless languages.is_a?(Array)
  end

  def profile_photo_is_safe
    return unless profile_photo.attached?

    unless PROFILE_PHOTO_CONTENT_TYPES.include?(profile_photo.blob.content_type)
      errors.add(:profile_photo, "must be a JPG, PNG, or WebP image")
    end
    if profile_photo.blob.byte_size > PROFILE_PHOTO_MAX_SIZE
      errors.add(:profile_photo, "must be smaller than 5 MB")
    end
  end
end
