class CarePartnerOnboardingProgress
  STEPS = (1..4).freeze

  attr_reader :care_partner

  def initialize(care_partner)
    @care_partner = care_partner
  end

  def unlocked_step
    [ calculated_unlocked_step, care_partner.onboarding_step ].min
  end

  def allows?(step)
    STEPS.cover?(step.to_i) && step.to_i <= unlocked_step
  end

  def complete?(step)
    missing_fields_for(step).empty?
  end

  def missing_fields_for(step)
    case step.to_i
    when 1 then profile_missing_fields
    when 2 then identity_missing_fields
    when 3 then service_missing_fields
    when 4 then review_missing_fields
    else []
    end
  end

  def all_missing_fields
    STEPS.flat_map { |step| missing_fields_for(step) }.uniq
  end

  def advance!
    care_partner.update!(onboarding_step: calculated_unlocked_step)
  end

  private

  def calculated_unlocked_step
    return 1 unless complete?(1)
    return 2 unless complete?(2)
    return 3 unless complete?(3)

    4
  end

  def profile_missing_fields
    profile = care_partner.profile
    return [ "care partner profile" ] if profile.blank?

    missing = []
    missing << "legal name" if profile.legal_name.blank?
    missing << "display name" if profile.display_name.blank?
    missing << "date of birth" if profile.date_of_birth.blank?
    missing << "profile photo" unless profile.profile_photo.attached?
    missing << "residential address" if profile.address.blank?
    missing << "city" if profile.city.blank?
    missing << "state or region" if profile.region.blank?
    missing << "country" if profile.country.blank?
    missing << "country code" if profile.country_code.blank?
    missing << "preferred language" if profile.languages.blank?
    missing << "emergency contact name" if profile.emergency_contact_name.blank?
    missing << "emergency contact phone" if profile.emergency_contact_phone.blank?
    missing << "location consent" unless profile.location_consent?
    missing
  end

  def identity_missing_fields
    care_partner.verification_documents.any? { |document| document.evidence_photos.attached? } ? [] : [ "identity document photos" ]
  end

  def service_missing_fields
    services = care_partner.care_partner_services.to_a
    missing = []
    missing << "service selection" if services.empty?
    missing << "service coverage area" unless services.any? { |service| service.service_zones.present? }
    missing << "introduction video link" if care_partner.profile&.introduction_video_url.blank?
    missing
  end

  def review_missing_fields
    missing = []
    missing << "payout method" if care_partner.payout_method_summary.blank?
    missing << "terms acceptance" if care_partner.terms_accepted_at.blank?
    missing << "privacy consent" if care_partner.privacy_accepted_at.blank?
    missing << "code of conduct acceptance" if care_partner.code_of_conduct_accepted_at.blank?
    missing << "service standards acceptance" if care_partner.service_standards_accepted_at.blank?
    missing
  end
end
