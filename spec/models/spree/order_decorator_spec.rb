require 'spec_helper'

describe Spree::Order, type: :model do

  it { should have_one :avalara_transaction }

  let(:order_with_line_items) {FactoryGirl.create(:order_with_line_items)}
  let(:variant) { create(:variant) }

  before :each do
    MyConfigPreferences.set_preferences
    stock_location = FactoryGirl.create(:stock_location)
    @order = FactoryGirl.create(:order)
    line_item = FactoryGirl.create(:line_item)
    line_item.tax_category.update_attributes(name: "Clothing", description: "PC030000")
    @order.line_items << line_item
    to_address = Spree::Address.create(firstname: "Allison", lastname: "Reilly", address1: "220 Paul W Bryant Dr", city: "Tuscaloosa", zipcode: "35401", phone: "9733492462", state_name: "Alabama", state_id: 39, country_id: 1)
    @order.update_attributes(ship_address: to_address, bill_address: to_address)
  end

  describe "#avalara_eligible" do
    it "should return true" do
      expect(@order.avalara_eligible).to eq(true)
    end
  end

  describe "#avalara_lookup" do
    it "should return lookup_avatax" do
      expect(@order.avalara_lookup).to eq(:lookup_avatax)
    end
    it "creates new avalara_transaction" do
      expect{@order.avalara_lookup}.to change{Spree::AvalaraTransaction.count}.by(1)
    end
  end

  describe "#avalara_capture" do
    it "should response with Spree::Adjustment object" do
      expect(@order.avalara_capture.first).to be_kind_of(Spree::Adjustment)
    end
    it "creates new avalara_transaction" do
      expect{@order.avalara_capture}.to change{Spree::AvalaraTransaction.count}.by(1)
    end
  end

  describe "#avalara_capture_finalize" do
    it "should response with Spree::Adjustment object" do
      expect(@order.avalara_capture_finalize.first).to be_kind_of(Spree::Adjustment)
    end
    it "creates new avalara_transaction" do
      expect{@order.avalara_capture_finalize}.to change{Spree::AvalaraTransaction.count}.by(1)
    end
  end

  describe "#display_avalara_tax_total" do
    it "is Spree::Money" do
      expect(@order.display_avalara_tax_total).to be_kind_of(Spree::Money)
    end
  end
  context "payment" do
    before do
      order_with_line_items.state = 'delivery'
    end
    it "should do avalara_capture" do
      order_with_line_items.should be_delivery
      expect(order_with_line_items).to receive(:avalara_capture)
      order_with_line_items.next!
    end
    it "should be at state payment" do
      order_with_line_items.next!
      order_with_line_items.should be_payment
    end
  end
  let(:promotion) { FactoryGirl.create(:promotion) }
  let(:calculator) { Spree::Calculator::FlatRate.new(:preferred_amount => 10) }
  let!(:action) { Spree::Promotion::Actions::CreateAdjustment.create(promotion: promotion, calculator: calculator) }

  context "running promotions" do

    before :each do
      order_with_line_items.variants << variant
      order_with_line_items.promotions << promotion
      order_with_line_items.avalara_capture
    end
    context "one active order promotion" do

      it "creates valid discount on order" do
        order_with_line_items.variants << variant
        expect(order_with_line_items.all_adjustments.to_a.sum(&:amount)).not_to eq 0
      end

      it "creates a promotion tax adjustment" do
        expect(order_with_line_items.all_adjustments).to include(Object)
      end

    end

    context "one active line item promotion" do
      let!(:action) { Spree::Promotion::Actions::CreateItemAdjustments.create(promotion: promotion, calculator: calculator) }

      it "creates valid discount on order" do
        order_with_line_items.variants << variant
        expect(order_with_line_items.line_item_adjustments.to_a.sum(&:amount)).not_to eq 0
      end

    end
  end
  context "complete" do
    before do
      @order.state = 'confirm'
    end
    it "should do avalara_capture" do
      expect(@order).to receive(:avalara_capture_finalize)
      @order.next!
    end
    it "should be at state complete" do
      @order.next!
      @order.should be_complete
    end
  end
end