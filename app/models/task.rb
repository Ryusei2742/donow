class Task < ApplicationRecord
  STATUSES = %w[pending active completed skipped].freeze

  belongs_to :user
  belongs_to :goal, optional: true
  has_many :work_sessions, dependent: :destroy

  enum :status, STATUSES.index_with(&:itself), default: :pending, validate: true

  attribute :scheduled_date, :date, default: -> { Date.current }

  validates :title, presence: true
  validates :status, presence: true
  validates :scheduled_date, presence: true
  validates :estimated_minutes, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validate :goal_belongs_to_user

  scope :scheduled_for, ->(date) { where(scheduled_date: date) }
  scope :recent_first, -> { order(scheduled_date: :desc, created_at: :desc) }

  def start!(planned_duration_seconds: nil)
    user.with_lock do
      with_lock do
        session = user.work_sessions.open.first

        if session && session.task_id != id
          errors.add(:base, "別のタスクが進行中です。完了または中断してから開始してください")
          raise ActiveRecord::RecordInvalid, self
        end

        update!(status: :active, completed_at: nil)

        if session && planned_duration_seconds.present? && !session.focus_timer?
          session.update!(status: :interrupted, ended_at: Time.current)
          session = nil
        end

        session || work_sessions.create!(
          user: user,
          started_at: Time.current,
          status: :active,
          planned_duration_seconds: planned_duration_seconds
        )
      end
    end
  end

  def complete!
    user.with_lock do
      with_lock do
        now = Time.current
        update!(status: :completed, completed_at: now)
        close_open_sessions!(:completed, now)
      end
    end
  end

  def interrupt!
    user.with_lock do
      with_lock do
        now = Time.current
        update!(status: :pending, completed_at: nil)
        close_open_sessions!(:interrupted, now)
      end
    end
  end

  def skip!
    user.with_lock do
      with_lock do
        now = Time.current
        update!(status: :skipped, completed_at: nil)
        close_open_sessions!(:interrupted, now)
      end
    end
  end

  def open_work_session
    work_sessions.open.order(started_at: :desc).first
  end

  private

  def goal_belongs_to_user
    return if goal.blank? || user.blank? || goal.user_id == user_id

    errors.add(:goal, "は自分の目標から選択してください")
  end

  def close_open_sessions!(new_status, ended_at)
    work_sessions.open.find_each do |session|
      session.update!(status: new_status, ended_at: ended_at)
    end
  end
end
