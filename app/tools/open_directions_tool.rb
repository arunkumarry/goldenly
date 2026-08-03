class OpenDirectionsTool < RubyLLM::Tool
  desc "Prepare user-initiated directions to a hospital. Never open maps without the person selecting Directions in the app."
  param :hospital_name, type: "string", desc: "Hospital name as said by the person, if known", required: false

  def initialize(context:)
    @context = context
  end

  def name = "open_directions"

  def execute(hospital_name: nil)
    { status: "confirmation_required", message: hospital_name.present? ? "Ask the person to confirm by pressing Directions for #{hospital_name} in the hospital list." : "Ask the person to choose a hospital card and press Directions." }
  end
end
