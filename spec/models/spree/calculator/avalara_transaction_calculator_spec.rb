require 'spec_helper'

describe Spree::Calculator::AvalaraTransactionCalculator, :type => :model do
  let!(:country) { create(:country) }
  let!(:zone) { create(:zone, :name => "North America", :default_tax => true, :zone_members => []) }
  let(:zone_member) { Spree::ZoneMember.create() }
  let!(:tax_category) { Spree::TaxCategory.create(name: 'Clothing', tax_code: 'P0000000') }
  let(:included_in_price) { false }
  let!(:rate) { create(:tax_rate, :tax_category => tax_category, :amount => 0.00, :included_in_price => included_in_price, zone: zone) }
  let!(:calculator) { Spree::Calculator::AvalaraTransactionCalculator.new(:calculable => rate ) }
  let!(:order) { create(:order_with_line_items) }
  let(:line_item) { order.line_items.first }

  before do
    MyConfigPreferences.set_preferences
    zone.zone_members.create!(zoneable: country)
    order.state = 'delivery'
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
        it "should raise error" do
          expect{calculator.compute(line_item)}.to raise_error(RuntimeError)
        end
      end

      context "when tax is not included in price" do
        context "when the line item is discounted" do
          before { line_item.promo_total = -1 }

          it "should be equal to the item's pre-tax total * rate" do
            expect(calculator.compute(line_item)).to eq(0.4)
          end
        end

        context "when the variant matches the tax category" do
          it "should be equal to the item pre-tax total * rate" do
            expect(calculator.compute(line_item)).to eq(0.4)
          end
        end
      end
    end

    context "when given a shipment" do
      let!(:shipping_tax_category) { Spree::TaxCategory.create(name: 'Shipping', tax_code: 'FR000000') }
      let!(:shipping_calculator) { Spree::Calculator::AvalaraTransactionCalculator.new(:calculable => rate ) }
      let!(:tax_rate) { create(:tax_rate, :tax_category => shipping_tax_category, :amount => 0.00, :included_in_price => false, zone: zone) }

      before do
        order.shipments.first.selected_shipping_rate.update_attributes(tax_rate: tax_rate)
        order.reload
        order.state = 'delivery'
      end

      it "should be equal 0.6" do
        expect(calculator.compute(order.shipments.first)).to eq(4.0)
      end

      it "takes discounts into consideration" do
        order.shipments.first.update_attributes(promo_total: -1)
        expect(calculator.compute(order.shipments.first)).to eq(3.96)
      end
      context 'when given a shipping rate' do
        it 'raises exception' do
          order.shipments.first.selected_shipping_rate.tax_rate.update_attributes(included_in_price: true)
          expect{calculator.compute(order.shipments.first.selected_shipping_rate)}.to raise_exception
        end
      end
    end
  end
end
