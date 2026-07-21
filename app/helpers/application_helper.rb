module ApplicationHelper
  SUPPORTED_LANGUAGES = [ "English", "Telugu", "Hindi", "Spanish", "Chinese (Mandarin)", "Arabic", "French", "German", "Portuguese", "Japanese", "Korean" ].freeze
  CALLING_CODES = [ [ "India +91", "+91" ], [ "United States / Canada +1", "+1" ], [ "United Kingdom +44", "+44" ], [ "Australia +61", "+61" ], [ "Singapore +65", "+65" ], [ "United Arab Emirates +971", "+971" ] ].freeze

  def hour_options
    (0..23).map { |hour| [ Time.zone.local(2000, 1, 1, hour).strftime("%-I %p"), hour ] }
  end
end
