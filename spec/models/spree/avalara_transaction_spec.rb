require 'spec_helper'

describe Spree::AvalaraTransaction, :type => :model do

  it { should belong_to :order }
  it { should belong_to :return_authorization }
  it { should validate_presence_of :order }
  it { should have_db_index :order_id }
  it { should have_one :adjustment }

  before :each do
    MyConfigPreferences.set_preferences
    stock_location = FactoryGirl.create(:stock_location)
    @order = FactoryGirl.create(:order)
    line_item = FactoryGirl.create(:line_item)
    line_item.tax_category.update_attributes(name: "Clothing", description: "PC030000")
    @order.line_items << line_item
    to_address = Spree::Address.create(firstname: "Allison", lastname: "Reilly", address1: "220 Paul W Bryant Dr", city: "Tuscaloosa", zipcode: "35401", phone: "9733492462", state_name: "Alabama", state_id: 39, country_id: 1)
    @order.bill_address = to_address
    @order.ship_address = to_address
  end

  describe "#rnt_tax" do
    it "should return @myrnttax variable" do
      @order.avalara_lookup
      expect(@order.avalara_transaction.rnt_tax).to eq(@rnt_tax)
    end
  end
  describe "#amount" do
    it "should return @myrnttax variable" do
      @order.avalara_lookup
      expect(@order.avalara_transaction.amount).to eq(@rnt_tax)
    end
  end
  describe "#lookup_avatax" do
    it "should look up avatax" do
      @order.avalara_capture
      expect(@order.avalara_transaction.lookup_avatax).to eq("0.4")
    end
  end

  describe "#commit_avatax" do
    it "should commit avatax" do
      @order.avalara_capture
      expect(@order.avalara_transaction.commit_avatax(@order.line_items, @order)).to eq("0.4")
    end
  end

  describe "#commit_avatax_final" do
    it "should commit avatax final" do
      @order.avalara_capture
      expect(@order.avalara_transaction.commit_avatax_final(@order.line_items, @order, @order.number.to_s + ":" + @order.id.to_s, @order.completed_at)).to eq("0.4")
    end
    it "should fail to commit to avatax if settings are false" do
      Spree::Config.avatax_document_commit = false

      @order.avalara_capture
      expect(@order.avalara_transaction.commit_avatax_final(@order.line_items, @order, @order.number.to_s + ":" + @order.id.to_s, @order.completed_at)).to eq("avalara document committing disabled")
    end
  end
end
