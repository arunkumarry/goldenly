class ServiceCatalog < ApplicationRecord
  has_many :service_requests, dependent: :restrict_with_error

  enum :kind, {
    medical_health_checkup: 0,
    household_help: 1,
    shopping: 2,
    transport: 3,
    companion_visit: 4,
    digital_assistance: 5,
    diagnostic_service: 6
  }

  validates :name, :description, presence: true
  validates :kind, uniqueness: true
  validates :member_price_cents, :partner_earning_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :currency, inclusion: { in: %w[USD INR] }

  scope :available, -> { where(active: true).order(:kind) }
  scope :clinical_services, -> { where(clinical: true) }

  def estimated_partner_earnings
    EarningsLedgerEntry::MoneyAmount.new(partner_earning_cents, currency).to_s
  end

  def member_price
    EarningsLedgerEntry::MoneyAmount.new(member_price_cents, currency).to_s
  end

  def self.for_service_type(service_type)
    normalized = service_type.to_s.downcase
    kind = case normalized
    when /diagnostic|blood|x[ -]?ray|urine|kidney|lab(?:oratory)?|scan|pathology/ then :diagnostic_service
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
