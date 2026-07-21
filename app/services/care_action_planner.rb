class CareActionPlanner
  TELUGU = /[\u0C00-\u0C7F]/.freeze
  EMERGENCY_TERMS = /\b(sos|emergency|urgent help|help me now|ambulance)\b|అత్యవసర|అర్జెంట్|సహాయం కావాలి|ప్రమాదం/i.freeze
  SERVICE_TERMS = /\b(health\s*check(?:up)?|healthcare|doctor|nurse|physio|physiotherapy|therapy|caregiver|support request|household|cleaning|cooking|errand|shopping|groceries|transport|ride|companion|digital assistance|phone help|device help|diagnostic|blood\s*test|x[ -]?ray|urine\s*test|kidney\s*test|lab(?:oratory)?\s*test|scan|pathology)\b|ఆరోగ్య|డాక్టర్|నర్స్|ఫిజియో|థెరపీ|రక్త పరీక్ష|ఎక్స్‌రే|మూత్ర పరీక్ష|కిడ్నీ పరీక్ష/i.freeze
  REMINDER_TERMS = /\b(remind|reminder|medicine|tablet|medication)\b|మందు|గుర్తు చేయి/i.freeze

  def initialize(care_profile:, message:, pending_service: nil)
    @care_profile = care_profile
    @message = message.to_s.squish
    @pending_service = pending_service
  end

  def plan
    return emergency_plan if @message.match?(EMERGENCY_TERMS)
    return nil if recorded_service_question?
    return continued_service_plan if @pending_service.present?
    return service_plan if @message.match?(SERVICE_TERMS) && scheduled_time
    return service_details_needed if @message.match?(SERVICE_TERMS)
    return reminder_plan if @message.match?(REMINDER_TERMS) && scheduled_time

    nil
  end

  private

  def recorded_service_question?
    @message.match?(SERVICE_TERMS) && @message.match?(/\b(when|what time|which day|do i have|am i|is .*scheduled)\b|ఎప్పుడు/i)
  end

  def emergency_plan
    number = CountryEmergencyNumber.for(@care_profile.country)
    {
      "type" => "emergency_alert",
      "title" => telugu? ? "అత్యవసర సహాయం" : "Emergency help",
      "summary" => telugu? ? "మీ విశ్వసనీయ పరిచయాలకు అలర్ట్ సిద్ధంగా ఉంది." : "An alert is ready for your trusted circle.",
      "confirmation" => telugu? ? "నిర్ధారించిన తర్వాత మాత్రమే అలర్ట్ నమోదు అవుతుంది. అవసరమైతే #{number} కు కాల్ చేయండి." : "The alert will be recorded only after confirmation. Call #{number} for immediate emergency help.",
      "emergency_number" => number,
      "message" => @message
    }
  end

  def service_details_needed(service_name: service_type, notes: @message)
    {
      "type" => "service_details_needed",
      "service_type" => service_name,
      "notes" => notes,
      "reply" => service_time_question(service_name),
      "pending_service" => { "service_type" => service_name, "notes" => notes }
    }
  end

  def continued_service_plan
    service_name = @pending_service.fetch("service_type")
    notes = [ @pending_service["notes"], @message ].compact.join("\n")
    return service_details_needed(service_name: service_name, notes: notes) unless scheduled_time

    service_plan(service_name: service_name, notes: notes)
  end

  def service_plan(service_name: service_type, notes: @message)
    {
      "type" => "service_request",
      "title" => telugu? ? "ఆరోగ్య సహాయ అభ్యర్థన" : "Health support request",
      "summary" => telugu? ? "మీ అభ్యర్థనను నిర్ధారణ కోసం సిద్ధం చేశాను." : "I prepared your request for confirmation.",
      "confirmation" => telugu? ? "నిర్ధారించిన తర్వాతే ప్రొవైడర్ అభ్యర్థన సృష్టించబడుతుంది." : "A provider request will be created only after you confirm.",
      "service_type" => service_name,
      "notes" => notes,
      "preferred_time" => scheduled_time&.iso8601
    }
  end

  def service_time_question(service_name)
    return "మీ #{service_name} కోసం ఏ రోజు, ఏ సమయం సౌకర్యంగా ఉంటుంది? ఉదాహరణకు, రేపు ఉదయం 10 గంటలకు అని చెప్పండి." if telugu?

    "I can arrange a #{service_name.downcase}. What day and time would work best? For example, tomorrow at 10 AM."
  end

  def reminder_plan
    {
      "type" => "reminder",
      "title" => telugu? ? "రిమైండర్ సిద్ధంగా ఉంది" : "Reminder ready",
      "summary" => telugu? ? "మీ కోసం ఒక రిమైండర్‌ను సిద్ధం చేశాను." : "I prepared a reminder for you.",
      "confirmation" => telugu? ? "నిర్ధారించిన తర్వాత మాత్రమే రిమైండర్ సేవ్ అవుతుంది." : "The reminder will be saved only after you confirm.",
      "reminder_title" => @message,
      "scheduled_for" => scheduled_time.iso8601
    }
  end

  def scheduled_time
    match = @message.match(/\b(?:at\s*)?(\d{1,2})(?::(\d{2}))?\s*(am|pm)\b/i)
    return unless match

    hour = match[1].to_i % 12
    hour += 12 if match[3].downcase == "pm"
    day = @message.match?(/\btomorrow\b|రేపు/i) ? Time.zone.tomorrow : Time.zone.today
    time = Time.zone.local(day.year, day.month, day.day, hour, match[2].to_i)
    time > Time.current || @message.match?(/\btomorrow\b|రేపు/i) ? time : time + 1.day
  end

  def service_type
    return "Diagnostic Service" if @message.match?(/diagnostic|blood\s*test|x[ -]?ray|urine\s*test|kidney\s*test|lab(?:oratory)?\s*test|scan|pathology|రక్త పరీక్ష|ఎక్స్‌రే|మూత్ర పరీక్ష|కిడ్నీ పరీక్ష/i)
    return "Household Help" if @message.match?(/household|cleaning|cooking|errand/i)
    return "Shopping" if @message.match?(/shopping|groceries/i)
    return "Transport" if @message.match?(/transport|ride/i)
    return "Companion Visit" if @message.match?(/companion/i)
    return "Digital Assistance" if @message.match?(/digital assistance|phone help|device help/i)
    return "Physiotherapy" if @message.match?(/physio|therapy|ఫిజియో|థెరపీ/i)
    return "Medical Health Checkup" if @message.match?(/health\s*check(?:up)?|ఆరోగ్య/i)

    "Medical Health Checkup"
  end

  def telugu?
    @message.match?(TELUGU) || @care_profile.preferred_language.to_s.casecmp?("Telugu")
  end
end
