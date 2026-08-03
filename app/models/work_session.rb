class WorkSession < ApplicationRecord
  STATUSES = %w[active completed interrupted].freeze
  FOCUS_DURATION_SECONDS = 5.minutes.to_i
  EXTENSION_SECONDS = [ 5.minutes.to_i, 10.minutes.to_i ].freeze

  belongs_to :task
  belongs_to :user
  belongs_to :avoidance_rule, optional: true

  enum :status, STATUSES.index_with(&:itself), default: :active, validate: true

  validates :started_at, presence: true
  validates :status, presence: true
  validates :planned_duration_seconds,
            numericality: { only_integer: true, greater_than: 0 },
            allow_nil: true
  validate :ended_at_is_after_started_at
  validate :user_owns_task
  validate :user_owns_avoidance_rule
  validate :only_one_open_session_per_user

  before_validation :set_user_from_task
  before_validation :snapshot_avoidance_rule_title, on: :create

  scope :recent_first, -> { order(started_at: :desc) }
  scope :open, -> { active.where(ended_at: nil) }
  scope :focus_timers, -> { where.not(planned_duration_seconds: nil) }

  def duration_minutes
    return unless ended_at

    ((ended_at - started_at) / 60).round
  end

  def focus_timer?
    planned_duration_seconds.present?
  end

  def ends_at
    return unless focus_timer?

    started_at + planned_duration_seconds.seconds
  end

  def remaining_seconds(at: Time.current)
    return unless focus_timer?

    [ (ends_at - at).ceil, 0 ].max
  end

  def extend_by!(seconds)
    seconds = Integer(seconds)
    raise ArgumentError, "延長時間が不正です" unless EXTENSION_SECONDS.include?(seconds)

    with_lock do
      unless active? && ended_at.nil? && focus_timer?
        errors.add(:base, "進行中の集中タイマーではありません")
        raise ActiveRecord::RecordInvalid, self
      end

      update!(planned_duration_seconds: planned_duration_seconds + seconds)
    end
  end

  private

  def set_user_from_task
    self.user ||= task&.user
  end

  def user_owns_task
    return if user.blank? || task.blank? || user_id == task.user_id

    errors.add(:user, "はタスクの所有者と一致していません")
  end

  def user_owns_avoidance_rule
    return if avoidance_rule.blank? || user.blank? || avoidance_rule.user_id == user_id

    errors.add(:avoidance_rule, "は自分のやらないことから選択してください")
  end

  def snapshot_avoidance_rule_title
    self.avoidance_rule_title = avoidance_rule.title if avoidance_rule
  end

  def only_one_open_session_per_user
    return unless active? && ended_at.nil? && user_id.present?

    other_open_session = self.class.open.where(user_id: user_id).where.not(id: id).exists?
    errors.add(:status, "の作業セッションは同時に1件だけ開始できます") if other_open_session
  end

  def ended_at_is_after_started_at
    return if ended_at.blank? || started_at.blank? || ended_at >= started_at

    errors.add(:ended_at, "は開始日時より後にしてください")
  end
end
