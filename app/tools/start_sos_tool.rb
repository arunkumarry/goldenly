class StartSosTool < RubyLLM::Tool
  desc "Prepare an SOS alert for explicit user-requested emergency help. Never call emergency services, share location, or notify anyone without explicit confirmation."

  def initialize(context:)
    @context = context
  end

  def name = "start_sos"

  def execute
    @context.action_proposal = CareActionPlanner.new(care_profile: @context.care_profile, message: "SOS emergency help").plan
    { status: "confirmation_required", emergency_number: @context.action_proposal.fetch("emergency_number"), message: "Present the SOS confirmation UI and emergency call button. Do not trigger either automatically." }
  end
end
