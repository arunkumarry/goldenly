class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("EMAIL_FROM", "Goldenly <no-reply@goldenly.local>")
  layout "mailer"
end
