class VerificationMailer < ApplicationMailer
  def verification_code
    @code = params.fetch(:code)
    mail(to: params.fetch(:identifier), subject: "Your Goldenly verification code")
  end
end
