FactoryGirl.define do
  factory :request_hash, class: Hash do
    Commit false
    CustomerCode '1'
    DocDate '2014-11-03'
    CompanyCode '54321'
    CustomerUsageType ''
    ExemptionNo nil
    Client AVATAX_CLIENT_VERSION
    DocCode 'R731071205'
    ReferenceCode 'R731071205'
    DetailLevel 'Tax'
    DocType 'SalesOrder'
    Discount '0.00'
    Addresses [{:AddressCode=>'9', :Line1=>'31 South St', :City=>'Morristown', :PostalCode=>'07960', :Country=>'US'},{:AddressCode=>'Dest', :Line1=>'73 Glenmere Drive', :Line2=>'', :City=>'Chatham', :Region=>'NJ', :Country=>'US', :PostalCode=>'07928'},{:AddressCode=>'Orig', :Line1=>'73 Glenmere Drive', :City=>'Chatham', :PostalCode=>'07928', :Country=>'United States'}]
    Lines [{:LineNo=>'1-LI', :ItemCode=>'ROR-00013', :Qty=>3, :Amount=>62.97, :OriginCode=>'9', :DestinationCode=>'Dest', :Description=>'Ruby on Rails Jr. Spaghetti', :TaxCode=>'P0000000', :Discounted=>false}]
  end

  factory :avalara_transaction_calculator, class: Spree::Calculator::AvalaraTransactionCalculator do
  end

  factory :avalara_entity_use_code, class: Spree::AvalaraEntityUseCode do
    use_code 'A'
    use_code_description 'Federal government'
  end

  factory :us_zone, class: Spree::Zone do
    name { "USA - #{rand(999999)}" }
    description { generate(:random_string) }
    transient do
      zone_members_count 1
    end
    after(:create) do |zone, evaluator|
      create_list(:zone_member, evaluator.zone_members_count, zone: zone)
    end
  end

  factory :clothing_tax_rate, class: Spree::TaxRate do
    name 'Tax'
    amount 0.0
    tax_category { Spree::TaxCategory.find_or_create_by(tax_code: 'PC030000') }
    association(:calculator, factory: :avalara_transaction_calculator)
    zone { Spree::Zone.find_or_create_by(name: 'GlobalZone') }
    show_rate_in_label false
  end

  factory :shipping_tax_rate, class: Spree::TaxRate do
    name 'Shipping Tax'
    amount 0.0
    tax_category { create(:tax_category, tax_code: 'FR000000') }
    association(:calculator, factory: :avalara_transaction_calculator)
    zone { Spree::Zone.find_or_create_by(name: 'GlobalZone') }
    show_rate_in_label false
  end

  factory :avalara_order, class: Spree::Order do
    user
    bill_address
    ship_address
    completed_at nil
    email { user.email }
    store
    state 'delivery'

    transient do
      line_items_price BigDecimal.new(10)
      line_items_count 1
      line_items_quantity 1
      shipment_cost 5
      tax_category Spree::TaxCategory.first
    end

    before(:create) do |order, evaluator|
      if Spree::Country.count == 0
        create(:country, name: 'United States')
      end
      if Spree::Zone.find_by(name: 'GlobalZone').nil?
        create(:global_zone, default_tax: true)
      end
      if Spree::TaxCategory.first.nil?
        create(:clothing_tax_rate, tax_category: create(:tax_category))
      else
        create(:clothing_tax_rate, tax_category: Spree::TaxCategory.first)
      end
    end

    after(:create) do |order, evaluator|
      create_list(:line_item, evaluator.line_items_count, order: order, price: evaluator.line_items_price, tax_category: evaluator.tax_category, quantity: evaluator.line_items_quantity)
      order.line_items.reload

      create(:avalara_shipment, order: order, cost: evaluator.shipment_cost )
      order.shipments.reload

      order.update_with_updater!
      order.next
    end

    factory :completed_avalara_order do
      state 'complete'

      after(:create) do |order|
        # order.refresh_shipment_rates
        order.update_column(:completed_at, Time.now)
      end
    end
  end

  factory :avalara_shipping_method, class: Spree::ShippingMethod do
    zones { |a| [Spree::Zone.find_by(name: 'GlobalZone') || create(:zone, :with_country, default_tax: true)] }
    name 'Avalara Ground'
    code 'Avalara_Ground'
    association(:calculator, factory: :shipping_calculator, strategy: :create)

    before(:create) do |shipping_method, evaluator|
      if Spree::Country.count == 0
        create(:country)
      end
      shipping_tax_rate = create(:shipping_tax_rate)
      shipping_method.tax_category = shipping_tax_rate.tax_category
      if shipping_method.shipping_categories.empty?
        shipping_method.shipping_categories << (Spree::ShippingCategory.first || create(:shipping_category))
      end
    end
  end

  factory :avalara_shipment, class: Spree::Shipment do
    tracking 'U10000'
    cost BigDecimal.new(10)
    state 'pending'
    order
    stock_location

    after(:create) do |shipment, evalulator|
      shipment.add_shipping_method(create(:avalara_shipping_method), true)

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

FactoryGirl.modify do
  factory :tax_category, class: Spree::TaxCategory do
    name { "TaxCategory - #{rand(999999)}" }
    tax_code { 'PC030000' }
  end

  factory :zone_member, class: Spree::ZoneMember do
    association :zoneable, factory: :country
  end

  factory :address, class: Spree::Address do
    firstname 'John'
    lastname 'Doe'
    company 'Company'
    address1 '915 S Jackson St'
    address2 ''
    city 'Montgomery'
    state_name 'Alabama'
    zipcode '36104'
    phone '555-555-0199'
    alternative_phone '555-555-0199'

    country { Spree::Country.find_or_create_by(name: 'United States', iso: 'US', iso_name: 'US') }

    state { Spree::State.find_or_create_by(name: 'Alabama', abbr: 'AL', country: Spree::Country.last) }

    after(:create) do |address, evalulator|
      zone = Spree::Zone.first || create(:global_zone)

      zone.zone_members.create(zoneable: address.country)

    end
  end
end
