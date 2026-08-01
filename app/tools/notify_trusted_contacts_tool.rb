class NotifyTrustedContactsTool < RubyLLM::Tool
  desc "Prepare a trusted-circle emergency notification only after an explicit user request. It always requires confirmation and follows SOS consent rules."
  param :message, type: "string", desc: "Short user-provided context for the alert", required: false

  def initialize(context:)
    @context = context
  end

  def name = "notify_trusted_contacts"

  def execute(message: nil)
    @context.action_proposal = CareActionPlanner.new(care_profile: @context.care_profile, message: "SOS emergency help #{message}".strip).plan
    { status: "confirmation_required", message: "Present confirmation before notifying the trusted circle. Do not send anything yet." }
  end
end
