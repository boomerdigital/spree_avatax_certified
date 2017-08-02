require 'spec_helper'

describe Spree::Calculator::AvalaraTransactionCalculator, :vcr do
  let(:included_in_price) { false }
  let(:tax_category) { Spree::TaxCategory.find_or_create_by(name: 'Clothing', tax_code: 'P0000000') }
  let(:calculator) { Spree::TaxRate.find_by(name: 'Tax').calculator }
  let(:line_item) { order.line_items.first }

  describe '#description' do
    it 'responds with avalara_transaction' do
      expect(Spree::Calculator::AvalaraTransactionCalculator.new.description).to eq('Avalara Transaction Calculator')
    end
  end

  context '#compute', :vcr do
    let!(:order) { create(:avalara_order, line_items_price: 10, shipment_cost: 100, tax_included: included_in_price) }

    context 'when given an order' do

      before do
        allow(order).to receive_messages :line_items => [line_item]
      end

      context 'when computing an order' do
        it 'should raise error' do
          expect{calculator.compute(order)}.to raise_error(RuntimeError)
        end
      end
    end
    context 'when computing a line item' do
      context 'when tax is included in price' do
        let(:included_in_price) { true }
        it 'should be equal to the item pre-tax total * rate' do
          expect(calculator.compute(line_item)).to eq(0.38)
        end

        it 'should be equal to the previous included_tax_total is order is at cart' do
          order.state = 'cart'
          line_item.included_tax_total = 0.1
          expect(calculator.compute(line_item)).to eq(0.1)
        end

        it 'should be equal to the previous included_tax_total is order is at address' do
          order.state = 'address'
          line_item.included_tax_total = 0.1
          expect(calculator.compute(line_item)).to eq(0.1)
        end
      end

      context 'when tax is not included in price' do

        it 'should be equal to the item pre-tax total * rate' do
          expect(calculator.compute(line_item)).to eq(0.4)
        end


        it 'should be equal to the previous additional_tax_total is order is at cart' do
          order.state = 'cart'
          line_item.additional_tax_total = 0.1
          expect(calculator.compute(line_item)).to eq(0.1)
        end

        it 'should be equal to the previous additional_tax_total is order is at address' do
          order.state = 'address'
          line_item.additional_tax_total = 0.1
          expect(calculator.compute(line_item)).to eq(0.1)
        end


        it 'should be equal to the previous tax total if preference tax_calculation is false' do
          Spree::Config.avatax_tax_calculation = false

          line_item.additional_tax_total = 0.1
          expect(calculator.compute(line_item)).to eq(0.1)
        end

        context "when the order is discounted" do
          let(:promotion) { create(:promotion, :with_order_adjustment, weighted_order_adjustment_amount: 2) }

          before do
            create(:adjustment, order: order, source: promotion.promotion_actions.first, adjustable: order)
            order.reload.update_with_updater!
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

            order.reload.update_with_updater!
          end

          it "should be equal to the item's pre-tax total * rate" do
            expect(calculator.compute(line_item)).to eq(0.32)
          end
        end
      end
    end

    context "when given a shipment" do
      let(:shipping_rate) { Spree::TaxRate.find_by(name: 'Shipping Tax') }
      let(:shipping_calculator) { Spree::Calculator::AvalaraTransactionCalculator.new(calculable: shipping_rate) }
      let!(:shipment) { order.shipments.first }

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
          expect(shipping_calculator.compute(order.shipments.first)).to eq(3.85)
        end
      end
    end
  end
end
