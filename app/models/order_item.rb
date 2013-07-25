class OrderItem < ActiveRecord::Base
  belongs_to :order
  belongs_to :part
  attr_accessible :count
end
