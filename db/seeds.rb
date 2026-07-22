# Reference catalogues and designated Goldenly operations accounts only.
# Personal member accounts, care profiles, reminders, and requests are never
# seeded. Email addresses can be changed per environment without changing code.
service_catalogues = [
  [ :medical_health_checkup, "Medical Health Checkup", "Book a medical health checkup." ],
  [ :household_help, "Household Help", "Help with household tasks and errands." ],
  [ :shopping, "Shopping", "Groceries and other essential shopping." ],
  [ :transport, "Transport", "Transport to appointments and other destinations." ],
  [ :companion_visit, "Companion Visit", "A friendly companion visit." ],
  [ :digital_assistance, "Digital Assistance", "Help with phones, devices, and digital services." ],
  [ :diagnostic_service, "Diagnostic Service", "Book diagnostic tests such as blood tests, X-rays, urine tests, and kidney tests." ]
]

service_catalogues.each do |kind, name, description|
  ServiceCatalog.find_or_initialize_by(kind: kind).update!(name: name, description: description, active: true)
end

admin_accounts = [
  {
    email_address: ENV.fetch("GOLDENLY_OPERATIONS_MANAGER_EMAIL", "goldenlyai@gmail.com"),
    full_name: "Goldenly Operations Manager"
  },
  {
    email_address: ENV.fetch("GOLDENLY_SUPER_ADMIN_EMAIL", "superadmin@goldenly.com"),
    full_name: "Goldenly Super Admin"
  }
]

admin_accounts.each do |attributes|
  email_address = attributes.fetch(:email_address).strip.downcase
  user = User.find_or_initialize_by(email_address: email_address)
  user.full_name = attributes.fetch(:full_name) if user.new_record?
  user.country = "Global" if user.new_record?
  # operations_manager is the highest existing operational role. It can enter
  # the separate admin workspace, review providers, and manage manual payouts.
  user.platform_role = :operations_manager
  user.save!
end
