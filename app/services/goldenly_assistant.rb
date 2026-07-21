require "net/http"
require "json"

# AI is intentionally limited to language understanding and coordination.
# Database mutations, contact notifications, and service dispatch remain behind
# explicit confirmation flows in their respective controllers/jobs.
class GoldenlyAssistant
  SAFETY_INSTRUCTIONS = <<~PROMPT.freeze
    You are Goldenly, a warm, concise member-care coordination assistant.
    Reply in the language used by the person whenever possible.
    You may help explain Goldenly features, prepare reminders, and prepare service requests.
    Never diagnose, prescribe, recommend treatment, or present clinical conclusions.
    For urgent or severe symptoms, advise the person to contact local emergency services or a qualified clinician.
    Do not claim that a reminder, booking, notification, or data share occurred. State that confirmation is required.
  PROMPT

  def initialize(message, member: nil)
    @message = message.to_s.strip
    @member = member
  end

  def reply
    return fallback if ENV["OPENAI_API_KEY"].blank? || ENV["OPENAI_MODEL"].blank?

    uri = URI("https://api.openai.com/v1/responses")
    request = Net::HTTP::Post.new(uri, {
      "Authorization" => "Bearer #{ENV.fetch('OPENAI_API_KEY')}",
      "Content-Type" => "application/json"
    })
    request.body = {
      model: ENV.fetch("OPENAI_MODEL"),
      instructions: [ SAFETY_INSTRUCTIONS, member_context ].compact.join("\n\n"),
      input: @message,
      store: false
    }.to_json

    response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 4, read_timeout: 12) { |http| http.request(request) }
    raise "OpenAI request failed (#{response.code})" unless response.is_a?(Net::HTTPSuccess)

    body = JSON.parse(response.body)
    body.fetch("output_text")
  rescue StandardError => error
    Rails.logger.warn("GoldenlyAssistant fallback: #{error.message}")
    fallback
  end

  private

  def member_context
    return unless @member

    reminders = @member.reminders.where(status: "pending").order(:scheduled_for).limit(5).map { |reminder| "#{reminder.title} at #{reminder.scheduled_for.strftime('%-d %b %-I:%M %p')}" }
    services = @member.service_requests.order(created_at: :desc).limit(3).map { |request| "#{request.service_type} (#{request.status})" }
    <<~CONTEXT
      Member context for this conversation (use only to answer this member):
      - Preferred language: #{@member.preferred_language}
      - Location: #{@member.location.presence || "not recorded"}, #{@member.country}
      - Upcoming reminders: #{reminders.any? ? reminders.join("; ") : "none recorded"}
      - Recent service requests: #{services.any? ? services.join("; ") : "none recorded"}
      Answer only from this context. Ask a short clarification if the answer is not recorded.
    CONTEXT
  end

  def fallback
    reminder = @member&.reminders&.where(status: "pending")&.order(:scheduled_for)&.first
    case @message
    when /when.*(medicine|tablet|reminder)|మందు.*ఎప్పుడు/i
      reminder ? "Your next recorded reminder is #{reminder.title} at #{reminder.scheduled_for.strftime('%-I:%M %p on %-d %b')}. Please check with your clinician before changing medicine or dosage." : "I do not have a recorded medicine schedule for this member. Please check the care plan or ask a clinician."
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
end
