class SosAlertDeliveryJob < ApplicationJob
  def perform(emergency_alert_id, actor_id = nil)
    alert = EmergencyAlert.find_by(id: emergency_alert_id)
    return unless alert&.confirmed?

    SosAlertDispatcher.new(emergency_alert: alert, actor: User.find_by(id: actor_id)).deliver!
  end
end
