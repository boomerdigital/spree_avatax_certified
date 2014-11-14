require 'spec_helper'

describe Spree::ReturnAuthorization, type: :model do
  MyConfigPreferences.set_preferences

  it { should have_one :avalara_transaction }

  before :each do
    @stock_location = FactoryGirl.create(:stock_location)
    @order = FactoryGirl.create(:shipped_order)
    @order.shipment_state = "shipped"
    @order.line_items.each do |line_item|
      line_item.tax_category.update_attributes(name: "Clothing", description: "PC030000")
    end
    @variant = @order.variants.first
    @return_authorization = Spree::ReturnAuthorization.create(:order => @order, :stock_location_id => @stock_location.id)
  end

  describe "#authorized" do
    it "returns inital state of authorized" do
      expect(@return_authorization.state).to eq("authorized")
    end
  end
  describe "#avalara_eligible" do
    it "should return true" do
      expect(@order.avalara_transaction.return_authorization.avalara_eligible).to eq(true)
    end
  end
  describe "#avalara_lookup" do
  end
  describe "#avalara_capture" do
it "should response with Spree::Adjustment object" do
      expect(@order.avalara_transaction.return_authorization.avalara_capture).to be_kind_of(Spree::Adjustment)
    end
    it "creates new avalara_transaction" do
      expect{@order.avalara_transaction.return_authorization.avalara_capture}.to change{Spree::AvalaraTransaction.count}.by(1)
    end
  end
  describe "#avalara_capture_finalize" do
  end
end