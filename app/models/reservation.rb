class Reservation < ApplicationRecord
  belongs_to :book, counter_cache: true

  validates :email, presence: true
end
