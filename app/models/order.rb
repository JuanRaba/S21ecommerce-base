class Order < ApplicationRecord
  belongs_to :user
  belongs_to :product
  belongs_to :billing, optional: true

  scope :cart, -> {where(payed: false)}
end
