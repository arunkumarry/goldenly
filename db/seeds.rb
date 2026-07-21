# A safe local demo account. Replace with authenticated onboarding data in production.
demo_user = User.find_or_initialize_by(email_address: "demo@goldenly.local")
demo_user.assign_attributes(
  full_name: "Anita Sharma",
  country: "India",
  location: "New Delhi",
  verified_at: Time.current
)
demo_user.save!

meera = Member.find_or_initialize_by(full_name: "Meera Sharma")
meera.assign_attributes(
  user: demo_user,
  country: "India",
  location: "New Delhi",
  phone_number: "+91 98765 43210",
  preferred_language: "English",
  mobility_needs: "Uses a walker for longer distances",
  emergency_contact_name: "Anita Sharma",
  emergency_contact_phone: "+91 98765 43211",
  sharing_preferences: { appointments: true, visit_status: true, medication_updates: true, emergency_alerts: true }
)
meera.save!

meera.reminders.find_or_create_by!(title: "Take Amlodipine", scheduled_for: Time.zone.today.change(hour: 9)) do |reminder|
  reminder.recurrence = "daily"
  reminder.status = "completed"
end
