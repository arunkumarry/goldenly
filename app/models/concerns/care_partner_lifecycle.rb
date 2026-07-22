module CarePartnerLifecycle
  extend ActiveSupport::Concern

  APPLICATION_TRANSITIONS = {
    "draft" => %w[submitted],
    "submitted" => %w[under_review changes_requested rejected],
    "under_review" => %w[changes_requested approved rejected],
    "changes_requested" => %w[submitted],
    "approved" => %w[active suspended],
    "active" => %w[suspended],
    "suspended" => %w[active rejected]
  }.freeze

  def transition_to!(next_status, note: nil)
    next_status = next_status.to_s
    unless APPLICATION_TRANSITIONS.fetch(application_status, []).include?(next_status)
      errors.add(:application_status, "cannot move from #{application_status.humanize} to #{next_status.humanize}")
      raise ActiveRecord::RecordInvalid, self
    end

    attributes = { application_status: next_status, review_note: note }
    attributes[:submitted_at] = Time.current if next_status == "submitted"
    attributes[:approved_at] = Time.current if next_status == "approved"
    attributes[:suspended_at] = Time.current if next_status == "suspended"
    attributes[:availability_status] = "available" if next_status == "active"
    attributes[:availability_status] = "paused" if %w[suspended rejected].include?(next_status)
    update!(attributes)
  end
end
