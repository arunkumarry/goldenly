class CallHospitalTool < RubyLLM::Tool
  desc "Prepare a user-initiated hospital call. Never place or initiate a call. Ask the person to select a hospital card and use its Call button."
  param :hospital_name, type: "string", desc: "Hospital name as said by the person, if known", required: false

  def initialize(context:)
    @context = context
  end

  def name = "call_hospital"

  def execute(hospital_name: nil)
    { status: "confirmation_required", message: hospital_name.present? ? "Ask the person to confirm by pressing Call for #{hospital_name} in the hospital list. Goldenly must not dial automatically." : "Ask the person to choose a hospital card and press Call. Goldenly must not dial automatically." }
  end
end
