class Book < ApplicationRecord
  has_many :reservations 

  enum :status, { available: 0, reserved: 1, loaned: 2 }

  validates :title, presence: true

end