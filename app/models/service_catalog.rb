class ServiceCatalog < ApplicationRecord
  has_many :service_requests, dependent: :restrict_with_error

  enum :kind, {
    medical_health_checkup: 0,
    household_help: 1,
    shopping: 2,
    transport: 3,
    companion_visit: 4,
    digital_assistance: 5
  }

  validates :name, :description, presence: true
  validates :kind, uniqueness: true

  scope :available, -> { where(active: true).order(:kind) }

  def self.for_service_type(service_type)
    normalized = service_type.to_s.downcase
    kind = case normalized
    when /household|clean|cook|errand/ then :household_help
    when /shop|grocery|essential/ then :shopping
    when /transport|ride/ then :transport
    when /companion|visit/ then :companion_visit
    when /digital|phone|device/ then :digital_assistance
    else :medical_health_checkup
    end

    find_by!(kind: kind)
  end
end
