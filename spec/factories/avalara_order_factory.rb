FactoryBot.define do
  factory :avalara_order, class: Spree::Order do
    user
    bill_address
    ship_address
    completed_at { nil }
    email { user.email }
    store
    state { 'delivery' }

    transient do
      line_items_price { BigDecimal(10) }
      line_items_count { 1 }
      line_items_quantity { 1 }
      shipment_cost { 5 }
      tax_category { Spree::TaxCategory.first }
      tax_included { false }
    end

    before(:create) do |order, evaluator|
      if Spree::Country.count == 0
        create(:country)
      end
      if Spree::Zone.find_by(name: 'GlobalZone').present?
        Spree::Zone.find_by(name: 'GlobalZone').update_attributes(default_tax: true)
      else
        create(:global_zone, default_tax: true)
      end

      if Spree::TaxCategory.first.nil?
        create(:clothing_tax_rate, tax_category: create(:tax_category), included_in_price: evaluator.tax_included)
      else
        create(:clothing_tax_rate, tax_category: Spree::TaxCategory.first, included_in_price: evaluator.tax_included)
      end
    end

    after(:create) do |order, evaluator|
      create_list(:line_item, evaluator.line_items_count,
                  order: order,
                  price: evaluator.line_items_price,
                  tax_category: evaluator.tax_category || Spree::TaxCategory.first,
                  quantity: evaluator.line_items_quantity)
      order.line_items.reload

      create(:avalara_shipment, order: order, cost: evaluator.shipment_cost, tax_included: evaluator.tax_included)
      order.shipments.reload

      order.update_with_updater!
      order.next
    end

    factory :completed_avalara_order do
      shipment_state { 'shipped' }
      payment_state { 'paid' }

      after(:create) do |order|
        # order.refresh_shipment_rates
        order.update_column(:completed_at, Time.now)
        order.update_column(:state, 'complete')
        payment = create(:payment, amount: order.total, order: order, state: 'completed')

        order.update_with_updater!
        order.next

        payment.avalara_finalize
      end
    end
  end
end
