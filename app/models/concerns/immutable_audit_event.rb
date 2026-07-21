module ImmutableAuditEvent
  extend ActiveSupport::Concern

  included do
    before_update :prevent_changes
    before_destroy :prevent_changes
  end

  private

  def prevent_changes
    errors.add(:base, "Audit events are immutable")
    throw :abort
  end
end
