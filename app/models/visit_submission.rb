class VisitSubmission < ApplicationRecord
  belongs_to :service_assignment

  enum :escalation_status, { not_escalated: "none", raised: "raised", resolved: "resolved" }, default: :not_escalated, prefix: :escalation

  validates :submitted_at, presence: true
  validate :checklist_is_object

  private

  def checklist_is_object
    errors.add(:checklist, "must be a checklist") unless checklist.is_a?(Hash)
  end
end
