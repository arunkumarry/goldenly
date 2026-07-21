class EmailVerificationCode < ApplicationRecord
  validates :identifier, :code_digest, :expires_at, presence: true
end
