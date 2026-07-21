class CareProfileLink < ApplicationRecord
  include CareProfilePermissions

  belongs_to :user
  belongs_to :care_profile

  enum :status, { pending: "pending", active: "active", revoked: "revoked" }, default: :active

  validates :relationship_to_person, presence: true
  validate :permissions_are_recognised

  def owner?
    care_profile.owned_by?(user)
  end

  def allows?(permission, capability = :view, emergency: false)
    return true if owner?

    super
  end

  def permission_summary
    return "Full profile access" if owner?

    permissions.filter_map do |permission, level|
      next if level == "none"

      "#{permission.humanize} (#{level.humanize})"
    end.join(", ")
  end

  private

  def permissions_are_recognised
    permissions.each do |permission, level|
      errors.add(:permissions, "contains an unsupported permission") unless CareProfilePermissions::CATALOGUE.include?(permission.to_s)
      errors.add(:permissions, "contains an unsupported access level") unless CareProfilePermissions::LEVELS.include?(level.to_s)
    end
  end
end
