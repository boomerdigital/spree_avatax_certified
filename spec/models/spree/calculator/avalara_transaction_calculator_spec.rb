require 'spec_helper'

describe Spree::Calculator::AvalaraTransactionCalculator, :type => :model do
  let!(:country) { create(:country) }
  let!(:zone) { create(:zone, :name => "Country Zone", :default_tax => true, :zone_members => []) }
  let!(:tax_category) { create(:tax_category, :tax_rates => []) }
  let!(:rate) { create(:tax_rate, :tax_category => tax_category, :amount => 0.05, :included_in_price => included_in_price) }
  let(:included_in_price) { false }
  let!(:calculator) { Spree::Calculator::AvalaraTransactionCalculator.new(:calculable => rate ) }
  let!(:order) { create(:order) }
  let!(:line_item) { create(:line_item, :price => 10, :quantity => 3, :tax_category => tax_category) }
  let!(:shipment) { create(:shipment, :cost => 15) }

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
          expect(calculator.compute(line_item)).to eq(1.45)
        end
      end

      context "when the variant matches the tax category" do
        it "should be equal to the item pre-tax total * rate" do
          expect(calculator.compute(line_item)).to eq(1.50)
        end
      end
    end

    context "when given a shipment" do
      it "should be 5% of 15" do
        expect(calculator.compute(shipment)).to eq(0.75)
      end

      it "takes discounts into consideration" do
        shipment.promo_total = -1
        # 5% of 14
        expect(calculator.compute(shipment)).to eq(0.7)
      end
    end
  end
end
