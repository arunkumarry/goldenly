class CareServiceRequestNotificationJob < ApplicationJob
  def perform(service_request_id, preferred_time_epoch)
    service_request = ServiceRequest.find_by(id: service_request_id)
    return unless service_request && %w[requested provider_assigned].include?(service_request.status)
    return unless service_request.preferred_time&.to_i == preferred_time_epoch

    CareNotificationDelivery.service_request(service_request)
  end
end
