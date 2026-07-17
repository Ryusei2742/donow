class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :goals, dependent: :destroy
  has_many :tasks, dependent: :destroy
  has_many :work_sessions

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: { case_sensitive: false }
end
