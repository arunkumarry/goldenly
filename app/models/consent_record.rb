class ConsentRecord < ApplicationRecord
  belongs_to :care_profile
  belongs_to :actor_user, class_name: "User", optional: true

  validates :subject, :purpose, :source, :captured_at, presence: true
end
