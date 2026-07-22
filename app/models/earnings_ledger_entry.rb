class EarningsLedgerEntry < ApplicationRecord
  belongs_to :care_partner_account
  belongs_to :service_assignment

  enum :status, {
    estimated: "estimated", pending_confirmation: "pending_confirmation", on_hold: "on_hold",
    available: "available", payout_processing: "payout_processing", paid: "paid", failed: "failed"
  }, default: :estimated

  validates :currency, inclusion: { in: %w[USD INR] }
  validates :service_value_cents, :goldenly_fee_cents, :net_payout_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  def amount
    MoneyAmount.new(net_payout_cents, currency)
  end

  class MoneyAmount
    def initialize(cents, currency)
      @cents = cents
      @currency = currency
    end

    def to_s
      symbol = @currency == "INR" ? "₹" : "$"
      "#{symbol}#{format('%.2f', @cents / 100.0)}"
    end
  end
end
