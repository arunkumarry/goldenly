require "net/http"

class GooglePlaces
  class ConfigurationError < StandardError; end
  class RequestError < StandardError; end

  AUTOCOMPLETE_URL = URI("https://places.googleapis.com/v1/places:autocomplete")
  DETAILS_BASE_URL = "https://places.googleapis.com/v1/places/".freeze

  def self.autocomplete(input:, session_token:)
    new.autocomplete(input:, session_token:)
  end

  def self.place(place_id:, session_token:)
    new.place(place_id:, session_token:)
  end

  def autocomplete(input:, session_token:)
    payload = request_json(
      AUTOCOMPLETE_URL,
      Net::HTTP::Post,
      headers: { "X-Goog-FieldMask" => "suggestions.placePrediction.placeId,suggestions.placePrediction.text" },
      body: { input:, sessionToken: session_token }
    )

    payload.fetch("suggestions", []).filter_map do |suggestion|
      prediction = suggestion["placePrediction"]
      next unless prediction

      { place_id: prediction["placeId"], text: prediction.dig("text", "text") }
    end
  end

  def place(place_id:, session_token:)
    payload = request_json(
      URI("#{DETAILS_BASE_URL}#{ERB::Util.url_encode(place_id)}?sessionToken=#{ERB::Util.url_encode(session_token)}"),
      Net::HTTP::Get,
      headers: { "X-Goog-FieldMask" => "id,formattedAddress,addressComponents,location" }
    )

    components = components_for(payload.fetch("addressComponents", []))
    {
      place_id: payload["id"],
      address: payload["formattedAddress"],
      city: components[:city],
      region: components[:region],
      country: components[:country],
      country_code: components[:country_code],
      postal_code: components[:postal_code],
      latitude: payload.dig("location", "latitude"),
      longitude: payload.dig("location", "longitude")
    }
  end

  private

  def api_key
    ENV.fetch("GOOGLE_MAPS_API_KEY")
  rescue KeyError
    raise ConfigurationError, "Google Maps Places is not configured. Set GOOGLE_MAPS_API_KEY."
  end

  def request_json(uri, request_class, headers:, body: nil)
    request = request_class.new(uri)
    request["X-Goog-Api-Key"] = api_key
    request["Content-Type"] = "application/json"
    headers.each { |name, value| request[name] = value }
    request.body = body.to_json if body

    response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 3, read_timeout: 5) { |http| http.request(request) }
    return JSON.parse(response.body) if response.is_a?(Net::HTTPSuccess)

    message = JSON.parse(response.body).dig("error", "message") rescue nil
    raise RequestError, message.presence || "Google Places could not complete this request."
  rescue SocketError, Net::OpenTimeout, Net::ReadTimeout => error
    raise RequestError, "Google Places is unavailable right now (#{error.class})."
  end

  def components_for(components)
    values = {}
    components.each do |component|
      types = component.fetch("types", [])
      text = component.dig("longText")
      short_text = component.dig("shortText")
      values[:city] ||= text if types.include?("locality") || types.include?("postal_town")
      values[:city] ||= text if types.include?("administrative_area_level_2")
      values[:region] ||= text if types.include?("administrative_area_level_1")
      values[:country] ||= text if types.include?("country")
      values[:country_code] ||= short_text if types.include?("country")
      values[:postal_code] ||= text if types.include?("postal_code")
    end
    values
  end
end
