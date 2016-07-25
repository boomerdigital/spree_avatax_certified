require 'spec_helper'

describe Spree::Calculator::AvalaraTransactionCalculator, :type => :model do
  let!(:country) { create(:country) }
  let!(:zone) { create(:zone, :name => "North America", :default_tax => true, :zone_members => []) }
  let(:zone_member) { Spree::ZoneMember.create() }
  let!(:tax_category) { Spree::TaxCategory.create(name: 'Clothing', tax_code: 'P0000000') }
  let(:included_in_price) { false }
  let!(:rate) { create(:tax_rate, :tax_category => tax_category, :amount => 0.00, :included_in_price => included_in_price, zone: zone) }
  let!(:calculator) { Spree::Calculator::AvalaraTransactionCalculator.new(:calculable => rate ) }
  let(:order) { create(:order_with_line_items, line_items_count: 5) }
  let(:line_item) { order.line_items.first }

  before :each do
    zone.zone_members.create!(zoneable: country)
    order.state = 'delivery'
  end

  describe '#description' do
    it 'responds with avalara_transaction' do
      expect(calculator.description).to eq('Avalara Transaction Calculator')
    end
  end

  context "#compute" do
    context "when given an order" do
      let!(:line_item_1) { line_item }
      let!(:line_item_2) { create(:line_item, :price => 10, :quantity => 3, :tax_category => tax_category) }

      before do
        allow(order).to receive_messages :line_items => [line_item_1, line_item_2]
      end

      context "when computing an order" do
        it "should raise error" do
          expect{calculator.compute(order)}.to raise_error(RuntimeError)
        end
      end
    end
    context "when computing a line item" do
      context "when tax is included in price" do
        let(:included_in_price) { true }
        it "should be equal to the item pre-tax total * rate" do
          expect(calculator.compute(line_item)).to eq(0.38)
        end
      end

      context "when tax is not included in price" do

        it "should be equal to the item pre-tax total * rate" do
          expect(calculator.compute(line_item)).to eq(0.4)
        end

        context "when the order is discounted" do
          let(:promotion) { create(:promotion, :with_order_adjustment) }

          before do
            create(:adjustment, order: order, source: promotion.promotion_actions.first, adjustable: order)
            order.update!
          end

          it "should be equal to the item's pre-tax total * rate" do
            expect(calculator.compute(line_item)).to eq(0.32)
          end
        end
        context "when the line item is discounted" do
          let!(:promotion) { create(:promotion_with_item_adjustment, adjustment_rate: 2) }

          before do
            order.line_items.each do |li|
              create(:adjustment, order: order, source: promotion.promotion_actions.first, adjustable: li)
            end
            order.update!
          end

          it "should be equal to the item's pre-tax total * rate" do
            expect(calculator.compute(line_item)).to eq(0.32)
          end
        end
      end
    end

    context "when given a shipment" do
      let!(:shipping_tax_category) { Spree::TaxCategory.create(name: 'Shipping', tax_code: 'FR000000') }
      let!(:shipping_calculator) { Spree::Calculator::AvalaraTransactionCalculator.new(:calculable => rate ) }
      let!(:shipping_rate) { create(:tax_rate, :tax_category => shipping_tax_category, :amount => 0.00, :included_in_price => false, zone: zone) }

      before do
        order.shipments.first.selected_shipping_rate.update_attributes(tax_rate: shipping_rate)
        order.reload
        order.state = 'delivery'
      end

      it "should be equal 4.0" do
        expect(shipping_calculator.compute(order.shipments.first)).to eq(4.0)
      end

      it "takes discounts into consideration" do
        order.shipments.first.update_attributes(promo_total: -1)
        expect(shipping_calculator.compute(order.shipments.first)).to eq(3.96)
      end

      context 'included_in_price' do
        let(:included_in_price) { true }
        it 'should be equal to 3.85' do
          expect(shipping_calculator.compute(order.shipments.first)).to eq(4.0)
        end
      end
    end
  end
end
