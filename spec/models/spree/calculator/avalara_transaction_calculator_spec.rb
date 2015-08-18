require 'spec_helper'

describe Spree::Calculator::AvalaraTransactionCalculator, type: :model do
  let!(:country) { create(:country) }
  let!(:zone) { create(:zone, name: 'North America', default_tax: true, zone_members: []) }
  let!(:tax_cat) { Spree::TaxCategory.create(name: 'Clothing', tax_code: 'P0000000') }
  let(:included_in_price) { false }
  let!(:rate) { create(:tax_rate, tax_category: tax_cat, amount: 0.00, included_in_price: included_in_price, zone: zone) }
  let!(:calculator) { Spree::Calculator::AvalaraTransactionCalculator.new(calculable: rate) }
  let!(:order) { create(:order) }
  let!(:line_item) { create(:line_item, price: 10, quantity: 3, tax_category: tax_cat) }
  let(:address) { Spree::Address.create(firstname: 'Allison', lastname: 'Reilly', address1: '220 Paul W Bryant Dr', city: 'Tuscaloosa', zipcode: '35401', phone: '9733492462', state_name: 'Alabama', state_id: 39, country_id: 1) }

  before :each do
    order.update_attributes(ship_address: address)
    zone.zone_members.create!(zoneable: country)
  end

  context '#compute' do
    context 'when given an order' do
      let!(:li_1) { line_item }
      let!(:li_2) { create(:line_item, price: 10, quantity: 3, tax_category: tax_cat) }

      before do
        allow(order).to receive_messages line_items: [li_1, li_2]
      end

      context 'when computing an order' do
        it 'should raise error' do
          expect { calculator.compute(order) }.to raise_error(RuntimeError)
        end
      end
    end
    context 'when computing a line item' do
      context 'when tax is included in price' do
        let(:included_in_price) { true }
        it 'should raise error' do
          expect { calculator.compute(line_item) }.to raise_error(RuntimeError)
        end
      end

      context 'when tax is not included in price' do
        context 'when the line item is discounted' do
          before { line_item.promo_total = -1 }

          it 'should be equal to the items pre-tax total * rate' do
            expect(calculator.compute(line_item)).to eq(1.2)
          end
        end

        context 'when the variant matches the tax category' do
          it 'should be equal to the item pre-tax total * rate' do
            expect(calculator.compute(line_item)).to eq(1.2)
          end
        end
      end
    end
    context 'when given a shipment' do
      let!(:shipping_tax_category) { Spree::TaxCategory.create(name: 'Shipping', tax_code: 'FR000000') }
      let!(:shipping_calculator) { Spree::Calculator::AvalaraTransactionCalculator.new(calculable: rate) }
      let!(:shipping_rate) { create(:tax_rate, tax_category: shipping_tax_category, amount: 0.00, included_in_price: false, zone: zone) }
      let!(:shipment) { create(:shipment, cost: 15) }

      before :each do
        shipment.shipping_method.update_attributes(tax_category: shipping_tax_category)
        shipment.selected_shipping_rate.update_attributes(tax_rate: Spree::TaxRate.last)
        shipment.order.line_items << line_item
      end

      it 'should be equal 0.6' do
        expect(calculator.compute(shipment)).to eq(0.6)
      end

      it 'takes discounts into consideration' do
        shipment.promo_total = -1
        expect(calculator.compute(shipment)).to eq(0.6)
      end
    end
  end
end
