class CountryEmergencyNumber
  NUMBERS = {
    "india" => "112",
    "united states" => "911",
    "united states of america" => "911",
    "usa" => "911",
    "canada" => "911",
    "united kingdom" => "999",
    "uk" => "999",
    "australia" => "000",
    "new zealand" => "111",
    "singapore" => "995",
    "united arab emirates" => "999"
  }.freeze

  def self.for(country)
    NUMBERS[country.to_s.strip.downcase] || "112"
  end
end
