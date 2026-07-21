# AI is intentionally limited to language understanding and coordination.
# Database mutations, contact notifications, and service dispatch remain behind
# explicit confirmation flows in their respective controllers/jobs.
class GoldenlyAssistant
  SAFETY_INSTRUCTIONS = <<~PROMPT.freeze
    You are Goldenly, a warm, concise care-profile coordination assistant.
    Reply in the language used by the person whenever possible.
    You may help explain Goldenly features, prepare reminders, and prepare service requests.
    For medicine questions, only repeat recorded reminder information. Never tell a person which medicine to take, or change a dose.
    Never diagnose, prescribe, recommend treatment, or present clinical conclusions.
    For urgent or severe symptoms, advise the person to contact local emergency services or a qualified clinician.
    Do not claim that a reminder, booking, notification, or data share occurred. State that confirmation is required.
  PROMPT

  def initialize(message, care_profile: nil, history: [])
    @message = message.to_s.strip
    @care_profile = care_profile
    @history = Array(history)
  end

  def reply
    return fallback if ENV["OPENAI_API_KEY"].blank? || ENV["OPENAI_MODEL"].blank?

    # RubyLLM's bundled model catalogue can lag behind OpenAI model releases.
    # The configured model is deliberately routed through OpenAI, with its
    # capabilities validated by OpenAI at request time.
    chat = RubyLLM.chat(
      model: ENV.fetch("OPENAI_MODEL"),
      provider: :openai,
      assume_model_exists: true
    ).with_instructions([ SAFETY_INSTRUCTIONS, care_profile_context ].compact.join("\n\n"))
    @history.each { |turn| chat.add_message(role: turn.fetch("role").to_sym, content: turn.fetch("content")) }
    chat.ask(@message).content
  rescue StandardError => error
    Rails.logger.warn("GoldenlyAssistant RubyLLM fallback: #{error.message}")
    fallback
  end

  private

  def care_profile_context
    return unless @care_profile

    reminders = @care_profile.reminders.order(:scheduled_for).limit(8).map { |reminder| "#{reminder.title} at #{reminder.scheduled_for.strftime('%-d %b %-I:%M %p')} (#{reminder.status})" }
    services = @care_profile.service_requests.order(preferred_time: :asc, created_at: :desc).limit(8).map do |request|
      time = request.preferred_time ? request.preferred_time.strftime("%-d %b %-I:%M %p") : "time to be arranged"
      "#{request.service_type} at #{time} (#{request.status})"
    end
    <<~CONTEXT
      Care profile context for this conversation (use only to answer this care profile):
      - Preferred language: #{@care_profile.preferred_language}
      - Location: #{@care_profile.location.presence || "not recorded"}, #{@care_profile.country}
      - Recorded reminders: #{reminders.any? ? reminders.join("; ") : "none recorded"}
      - Recorded service requests: #{services.any? ? services.join("; ") : "none recorded"}
      Answer only from this context. Ask a short clarification if the answer is not recorded.
    CONTEXT
  end

  def fallback
    return medication_answer if medication_question?
    return service_schedule_answer if service_schedule_question?

    reminder = @care_profile&.reminders&.where(status: "pending")&.order(:scheduled_for)&.first
    case @message
    when /when.*(medicine|tablet|reminder)|మందు.*ఎప్పుడు/i
      reminder ? "Your next recorded reminder is #{reminder.title} at #{reminder.scheduled_for.strftime('%-I:%M %p on %-d %b')}. Please check with your clinician before changing medicine or dosage." : "I do not have a recorded medicine schedule for this care profile. Please check the care plan or ask a clinician."
    when /medicine|tablet|remind/i
      "I can prepare a medicine reminder. Please confirm the medicine name and time before I notify anyone."
    when /doctor|pain|health|sick/i
      "I can help you request a health service or contact your trusted circle. For urgent symptoms, please call local emergency services."
    when ""
      "Tell me what you need help with. I can prepare a reminder or help you request a service."
    else
      "I understood your request. I’ll prepare it for your confirmation before creating a reminder, booking a service, or sharing it."
    end
  end

  def medication_question?
    @message.match?(/\b(medicine|tablet|medication|dose|eye drops|drops|capsule|pill|inhaler|insulin)\b|మందు/i)
  end

  def service_schedule_question?
    @message.match?(/\b(when|what time|which day|do i have|am i|is .*scheduled)\b|ఎప్పుడు/i) &&
      @message.match?(/health\s*check(?:up)?|doctor|nurse|physio|therapy|appointment|service|ఆరోగ్య|డాక్టర్|ఫిజియో|థెరపీ/i)
  end

  def medication_answer
    reminders = medication_reminders
    if reminders.any?
      recorded = reminders.first
      "Your recorded medication reminder is #{recorded.title} at #{recorded.scheduled_for.strftime('%-I:%M %p on %-d %b')}. I cannot tell you which medicine to take or change a dose—please follow the prescription or ask a clinician."
    else
      "I do not have a recorded medication reminder for this care profile. I cannot tell you which medicine to take; please follow the prescription or ask a clinician."
    end
  end

  def service_schedule_answer
    request = matching_service_request
    return "I do not have a recorded time for that service yet. I can help prepare a new request if you would like." unless request

    time = request.preferred_time ? request.preferred_time.strftime("%-I:%M %p on %-d %b") : "a time that is still to be arranged"
    "Your recorded #{request.service_type.downcase} is scheduled for #{time}. Its current status is #{request.status.humanize.downcase}."
  end

  def medication_reminders
    @care_profile&.reminders&.where("LOWER(title) ~ ?", "medicine|tablet|medication|dose|eye drops|drops|capsule|pill|inhaler|insulin")&.order(:scheduled_for) || []
  end

  def matching_service_request
    requests = @care_profile&.service_requests&.order(preferred_time: :asc, created_at: :desc) || []
    requests.find { |request| request.service_type.match?(/health|check|doctor|nurse|physio|therapy/i) } || requests.first
  end
end
