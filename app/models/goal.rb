class Goal < ApplicationRecord
  TITLE_MAX_LENGTH = 100
  FUTURE_MAX_LENGTH = 1_000

  belongs_to :user
  has_many :tasks, dependent: :nullify
  has_many :work_sessions, through: :tasks

  validates :title, presence: true, length: { maximum: TITLE_MAX_LENGTH }
  validates :desired_future, presence: true, length: { maximum: FUTURE_MAX_LENGTH }
  validates :avoided_future, presence: true, length: { maximum: FUTURE_MAX_LENGTH }

  def starts_this_week_count(at: Time.current)
    week = at.in_time_zone.all_week

    work_sessions.where(user_id: user_id, started_at: week).count
  end
end
