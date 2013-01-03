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


  def lookup

  end


  def commit

  end


  def create_cart_items

    cart_items.clear

    index = 0

    order.line_items.each do |line_item|

      cart_items.create!({

                             :index => (index += 1),

                             :tax_category => '20020', # TODO   CLOTHING-ACCESSORY

                             :sku => line_item.variant.sku.presence || line_item.variant.id,

                             :quantity => line_item.quantity,

                             :price => line_item.price.to_f,

                             :line_item => line_item

                         })

    end

    cart_items.create!({

                           :index => (index += 1),

                           :tic => '11010',

                           :sku => 'SHIPPING',

                           :quantity => 1,

                           :price => order.ship_total.to_f

                       })

  end



  private
  def post_order_to_avalara(commit=false)
    #Create array for line items
    tax_line_items=Array.new

    self.line_items.each_with_index do |line_item, i|
      line_item_total=line_item.price*line_item.quantity
      line=Avalara::Request::Line.new(:line_no => i, :origin_code => 1, :destination_code => 1, :qty => line_item.quantity, :amount => line_item_total)
      tax_line_items<<line
    end

    #Billing Address
    address=Avalara::Request::Address.new(:address_code => 1)
    address.line_1=self.order.billing_address.address1
    address.postal_code=self.order.billing_address.zipcode

    addresses=Array.new
    addresses<<address

    invoice=Avalara::Request::Invoice.new
    invoice.doc_code=self.number
    invoice.customer_code="TheRealReal"
    invoice.addresses=addresses
    invoice.lines=tax_line_items
    #A record is created when commit is true + doc_type is SalesInvoice
    if commit
      invoice.commit=true
      invoice.doc_type="SalesInvoice"
    end
    response=Avalara.get_tax(invoice)
    response
  end

end