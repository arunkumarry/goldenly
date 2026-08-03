class ChangeSearchLocationTool < RubyLLM::Tool
  desc "Ask the app to let the person choose a different authorised location for a hospital search. This tool never reads device location by itself."

  def initialize(context:)
    @context = context
  end

  def name = "change_search_location"

  def execute
    @context.location_change_requested = true
    { status: "needs_location_choice", message: "Ask the person to choose saved address, current device location, or another authorised address." }
  end
end
