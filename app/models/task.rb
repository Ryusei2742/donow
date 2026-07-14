class Task < ApplicationRecord
  STATUSES = %w[pending active completed skipped].freeze

  has_many :work_sessions, dependent: :destroy

  enum :status, STATUSES.index_with(&:itself), default: :pending, validate: true

  attribute :scheduled_date, :date, default: -> { Date.current }

  validates :title, presence: true
  validates :status, presence: true
  validates :scheduled_date, presence: true
  validates :estimated_minutes, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true

  scope :scheduled_for, ->(date) { where(scheduled_date: date) }
  scope :recent_first, -> { order(scheduled_date: :desc, created_at: :desc) }

  def start!
    with_lock do
      update!(status: :active, completed_at: nil)
      work_sessions.create!(started_at: Time.current, status: :active) unless open_work_session
    end
  end

  def complete!
    with_lock do
      now = Time.current
      update!(status: :completed, completed_at: now)
      close_open_sessions!(:completed, now)
    end
  end

  def interrupt!
    with_lock do
      now = Time.current
      update!(status: :pending, completed_at: nil)
      close_open_sessions!(:interrupted, now)
    end
  end

  def skip!
    with_lock do
      now = Time.current
      update!(status: :skipped, completed_at: nil)
      close_open_sessions!(:interrupted, now)
    end
  end

  def open_work_session
    work_sessions.active.where(ended_at: nil).order(started_at: :desc).first
  end

  private

  def close_open_sessions!(new_status, ended_at)
    work_sessions.active.where(ended_at: nil).find_each do |session|
      session.update!(status: new_status, ended_at: ended_at)
    end
  end
end
