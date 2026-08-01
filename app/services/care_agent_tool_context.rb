class CareAgentToolContext
  attr_reader :care_profile, :actor
  attr_accessor :hospital_search, :location_change_requested, :action_proposal

  def initialize(care_profile:, actor:)
    @care_profile = care_profile
    @actor = actor
  end
end
