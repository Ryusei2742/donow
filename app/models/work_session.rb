class WorkSession < ApplicationRecord
  STATUSES = %w[active completed interrupted].freeze

  belongs_to :task
  has_one :user, through: :task

  enum :status, STATUSES.index_with(&:itself), default: :active, validate: true

  validates :started_at, presence: true
  validates :status, presence: true
  validate :ended_at_is_after_started_at

  scope :recent_first, -> { order(started_at: :desc) }

  def duration_minutes
    return unless ended_at

    ((ended_at - started_at) / 60).round
  end

  private

  def ended_at_is_after_started_at
    return if ended_at.blank? || started_at.blank? || ended_at >= started_at

    errors.add(:ended_at, "は開始日時より後にしてください")
  end
end
