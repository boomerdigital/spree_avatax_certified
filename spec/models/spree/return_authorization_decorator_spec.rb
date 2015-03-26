require 'spec_helper'

describe Spree::ReturnAuthorization, type: :model do

  it { should have_one :avalara_transaction }
  let(:user) { FactoryGirl.create(:user) }
  let(:address) { FactoryGirl.create(:address) }

  before :each do
    MyConfigPreferences.set_preferences
    @stock_location = FactoryGirl.create(:stock_location)
    @order = FactoryGirl.create(:completed_order_with_totals)
    @order.shipments.each do |shipment|
      shipment.inventory_units.update_all state: 'shipped'
      shipment.update_column('state', 'shipped')
    end
    @order.reload
    @order.line_items.each do |line_item|
      line_item.tax_category.update_attributes(name: "Clothing", description: "PC030000")
    end
    @inventory_unit = @order.shipments.first.inventory_units.first
    @variant = @order.variants.first
    @return_authorization = Spree::ReturnAuthorization.create(:order => @order, :stock_location_id => @stock_location.id)
  end
  let(:return_authorization) { create(:return_authorization)}
  describe "#avalara_eligible" do
    it "should return true" do
      expect(@order.avalara_transaction.return_authorization.avalara_eligible).to eq(true)
    end
  end
  describe "#avalara_lookup" do
    it "should return lookup_avatax" do
      expect(@order.avalara_transaction.return_authorization.avalara_lookup).to eq(:lookup_avatax)
    end
  end
  describe "#avalara_capture" do
    it "creates new avalara_transaction" do
      expect{return_authorization}.to change{Spree::AvalaraTransaction.count}.by(1)
    end
  end

  describe "#authorized" do
    it "returns inital state of authorized" do
      expect(@order.avalara_transaction.return_authorization.state).to eq("authorized")
    end
  end

  context "received" do
    before do
      @order.avalara_transaction.return_authorization.inventory_units << @inventory_unit
      @order.avalara_transaction.return_authorization.state = "authorized"
      allow(@order).to receive(:update!)
    end
    it "should update order state" do
      @order.avalara_transaction.return_authorization.receive!
      expect(@order.avalara_transaction.return_authorization.state).to eq("received")
    end
    it "should receive avalara_capture_finalize" do
      @order.avalara_transaction.return_authorization.add_variant(@variant.id, 1)
      @order.avalara_transaction.return_authorization.receive!
      expect(@order.avalara_transaction.return_authorization).to receive(:avalara_capture_finalize)
    end

    it "should mark all inventory units are returned" do
      expect(@inventory_unit).to receive(:return!)
      @order.avalara_transaction.return_authorization.receive!
    end

    it "should update order state" do
      expect(@order).to receive :avalara_capture_finalize
      @order.avalara_transaction.return_authorization.receive!
    end

  end
end