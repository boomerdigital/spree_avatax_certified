require_dependency 'spree/order'

class SpreeAvalaraTransaction < ActiveRecord::Base
  # To change this template use File | Settings | File Templates.


  belongs_to :order

  validates :order, :presence => true

  has_one :adjustment, :as => :originator

  has_many :cart_items, :class_name => 'TaxCloudCartItem', :dependent => :destroy



  def amount
    cart_items.sum(&:amount)
  end

end