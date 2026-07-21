class DemoCareData
  def self.dashboard
    {
      member: { name: "Meera", greeting: "Good morning", wellbeing: "All good", wellbeing_note: "No concerns reported today" },
      next_visit: { title: "Physiotherapy", provider: "Ravi Kumar", time: "Today, 10:00 AM", eta: "45 min" },
      medications: [{ name: "Amlodipine", dosage: "1 tablet", time: "9:00 AM", status: "Taken" }, { name: "Vitamin D3", dosage: "1 capsule", time: "8:00 PM", status: "Upcoming" }],
      schedule: [{ time: "9:00 AM", title: "Medicine · Amlodipine", subtitle: "1 tablet", status: "Taken" }, { time: "10:00 AM", title: "Physiotherapy session", subtitle: "Caregiver: Ravi Kumar", status: "View" }, { time: "2:00 PM", title: "Blood test (home visit)", subtitle: "Pathkind Labs", status: "Upcoming" }, { time: "6:00 PM", title: "Evening walk", subtitle: "Set by Meera", status: "Reminder" }],
      services: [{ icon: "♡", name: "Health check-up", detail: "Starting ₹799", tone: "blue" }, { icon: "⌁", name: "Home blood test", detail: "Starting ₹699", tone: "sky" }, { icon: "✚", name: "Physiotherapy", detail: "Starting ₹699", tone: "red" }, { icon: "⌂", name: "Household help", detail: "Starting ₹399", tone: "blue" }, { icon: "▧", name: "Grocery & essentials", detail: "Starting ₹299", tone: "sky" }, { icon: "◌", name: "Tech assistance", detail: "Starting ₹299", tone: "red" }],
      timeline: [{ time: "Today, 10:00 AM", title: "Physiotherapy session completed", detail: "Caregiver: Ravi Kumar", type: "Visit" }, { time: "Today, 9:00 AM", title: "Blood pressure recorded", detail: "120/80 mmHg", type: "Health" }, { time: "Yesterday, 4:30 PM", title: "Blood test report uploaded", detail: "Pathkind Labs", type: "Document" }, { time: "Yesterday, 2:15 PM", title: "Household help completed", detail: "Caregiver: Sunita", type: "Visit" }],
      contacts: [{ name: "Anita", role: "Daughter", access: "Appointments, visits & emergencies" }, { name: "Raj", role: "Son", access: "Visit status & medication updates" }, { name: "Dr. Mehta", role: "Doctor", access: "Health documents" }]
    }
  end
end
