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
    line_item.tax_category.update_attributes(name: "Clothing", tax_code: "PC030000")
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

  describe "#cancel_status" do
    it "should return nil if no AvalaraTransaction is present" do
      expect(@order.cancel_status).to be_nil
    end

    it "should call #check_status on AvalaraTransaction" do
      avala_transaction = @order.create_avalara_transaction
      expect(avala_transaction).to receive(:check_status).with(@order)
      @order.cancel_status
    end
  end
  describe "#avalara_capture" do
    it "should response with Hash object" do
      expect(@order.avalara_capture).to be_kind_of(Hash)
    end
    it "creates new avalara_transaction" do
      expect{@order.avalara_capture}.to change{Spree::AvalaraTransaction.count}.by(1)
    end
  end

  describe "#avalara_capture_finalize" do
    it "should response with Hash object" do
      expect(@order.avalara_capture_finalize).to be_kind_of(Hash)
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