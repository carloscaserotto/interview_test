class Book < ApplicationRecord
  has_many :reservations, dependent: :destroy

  enum :status, { available: 0, reserved: 1, loaned: 2 }

  validates :title, presence: true

  scope :by_status, ->(status) { where(status: status) if status.present? }
  scope :search_title, ->(q) { where("title ILIKE ?", "%#{q}%") if q.present? }
end
