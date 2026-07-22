class CarePartnerVerificationDocument < ApplicationRecord
  EVIDENCE_PHOTO_CONTENT_TYPES = %w[image/jpeg image/png image/webp].freeze
  EVIDENCE_PHOTO_MAX_SIZE = 5.megabytes
  EVIDENCE_PHOTO_LIMIT = 2

  belongs_to :care_partner
  has_many_attached :evidence_photos

  enum :verification_status, { pending: "pending", approved: "approved", changes_requested: "changes_requested", rejected: "rejected" }, default: :pending

  validates :document_type, presence: true
  validates :country_code, length: { is: 2 }, allow_blank: true
  validate :evidence_photos_are_safe

  scope :current, -> { where("expires_on IS NULL OR expires_on >= ?", Date.current) }

  private

  def evidence_photos_are_safe
    unless evidence_photos.attached?
      errors.add(:evidence_photos, "must include at least one photo")
      return
    end

    if evidence_photos.length > EVIDENCE_PHOTO_LIMIT
      errors.add(:evidence_photos, "can include no more than #{EVIDENCE_PHOTO_LIMIT} photos")
    end

    evidence_photos.each do |photo|
      unless EVIDENCE_PHOTO_CONTENT_TYPES.include?(photo.blob.content_type)
        errors.add(:evidence_photos, "must be JPG, PNG, or WebP images")
      end

      if photo.blob.byte_size > EVIDENCE_PHOTO_MAX_SIZE
        errors.add(:evidence_photos, "must be smaller than 5 MB each")
      end
    end
  end
end
