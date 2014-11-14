require 'spec_helper'

describe Spree::Order, type: :model do
  MyConfigPreferences.set_preferences

  it { should have_one :avalara_transaction }

  let(:order_with_line_items) {FactoryGirl.create(:order_with_line_items)}
  before :each do
    stock_location = FactoryGirl.create(:stock_location)
    @order = FactoryGirl.create(:order)
    line_item = FactoryGirl.create(:line_item)
    line_item.tax_category.update_attributes(name: "Clothing", description: "PC030000")
    @order.line_items << line_item
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
      expect(@order.avalara_capture).to be_kind_of(Spree::Adjustment)
    end
    it "creates new avalara_transaction" do
      expect{@order.avalara_capture}.to change{Spree::AvalaraTransaction.count}.by(1)
    end
  end
  describe "#avalara_capture_finalize" do
    it "should response with Spree::Adjustment object" do
      expect(@order.avalara_capture_finalize).to be_kind_of(Spree::Adjustment)
    end
    it "creates new avalara_transaction" do
      expect{@order.avalara_capture_finalize}.to change{Spree::AvalaraTransaction.count}.by(1)
    end
  end
  context "payment" do
    before do
      order_with_line_items.state = 'delivery'
    end
    it "should do avalara_capture" do
      expect(order_with_line_items).to receive(:avalara_capture)
      order_with_line_items.next!
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
  end
end