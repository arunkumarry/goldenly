# Reference catalogues only. Personal accounts, care profiles, reminders, and
# requests are deliberately never seeded.
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
