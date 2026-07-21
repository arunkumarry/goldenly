module CareProfilePermissions
  extend ActiveSupport::Concern

  CATALOGUE = %w[
    appointments_routines
    service_requests
    medication_updates
    health_documents
    wellbeing_updates
    trusted_circle
    emergency_alerts
    sos_location
  ].freeze
  LEVELS = %w[none view manage emergency_only].freeze

  def self.full_access
    CATALOGUE.index_with { "manage" }
  end

  def permission_level(permission)
    permissions.fetch(permission.to_s, "none")
  end

  def allows?(permission, capability = :view, emergency: false)
    level = permission_level(permission)
    return true if level == "manage"
    return true if capability.to_sym == :view && level == "view"

    emergency && level == "emergency_only"
  end

  def can_grant?(requested_permissions)
    requested_permissions.to_h.all? do |permission, level|
      requested_level = level.to_s
      CareProfilePermissions::LEVELS.include?(requested_level) &&
        (requested_level == "none" || permission_level(permission) == "manage")
    end
  end
end
