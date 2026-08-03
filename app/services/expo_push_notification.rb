require "net/http"

class ExpoPushNotification
  ENDPOINT = URI("https://exp.host/--/api/v2/push/send")

  def self.deliver(tokens:, title:, body:, data: {})
    expo_tokens = tokens.select { |token| token.token.start_with?("ExponentPushToken[", "ExpoPushToken[") }
    return { status: "skipped", reason: "No Expo push tokens." } if expo_tokens.empty?

    request = Net::HTTP::Post.new(ENDPOINT, "Content-Type" => "application/json", "Accept" => "application/json")
    request.body = expo_tokens.map do |token|
      { to: token.token, title: title, body: body, sound: "default", priority: "high", data: data }
    end.to_json

    response = Net::HTTP.start(ENDPOINT.host, ENDPOINT.port, use_ssl: true, open_timeout: 5, read_timeout: 10) do |http|
      http.request(request)
    end
    return { status: "delivered" } if response.is_a?(Net::HTTPSuccess)

    Rails.logger.warn("Expo push notification failed with HTTP #{response.code}")
    { status: "failed", reason: "Expo returned HTTP #{response.code}." }
  rescue StandardError => error
    Rails.logger.warn("Expo push notification could not be delivered: #{error.class}: #{error.message}")
    { status: "failed", reason: "Expo push could not be delivered." }
  end
end
