FactoryBot.define do
  factory :avalara_shipment, class: Spree::Shipment do
    tracking { 'U10000' }
    cost { BigDecimal(10) }
    state { 'pending' }
    order
    stock_location

    transient do
      tax_included { false }
    end

    after(:create) do |shipment, evalulator|
      shipment.add_shipping_method(create(:avalara_shipping_method, tax_included: evalulator.tax_included), true)

      shipment.order.line_items.each do |line_item|
        line_item.quantity.times do
          shipment.inventory_units.create(
            order_id: shipment.order_id,
            variant_id: line_item.variant_id,
            line_item_id: line_item.id
          )
        end
      end
    end
  end
end
