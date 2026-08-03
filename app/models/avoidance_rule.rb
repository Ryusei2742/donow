class AvoidanceRule < ApplicationRecord
  TITLE_MAX_LENGTH = 100

  belongs_to :user
  has_many :work_sessions, dependent: :nullify

  normalizes :title, with: ->(title) { title.strip }

  validates :title,
            presence: true,
            length: { maximum: TITLE_MAX_LENGTH },
            uniqueness: { scope: :user_id, case_sensitive: false }

  scope :active, -> { where(active: true) }
end
