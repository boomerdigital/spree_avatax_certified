require 'spec_helper'

describe Spree::AvalaraTransaction, :type => :model do
  MyConfigPreferences.set_preferences

  it { should belong_to :order }
  it { should belong_to :return_authorization }
  it { should have_one :adjustment }
  it { should validate_presence_of :order }
  it { should have_db_index :order_id }

  before :each do
    order = FactoryGirl.create(:order)
    @avalara_transaction = Spree::AvalaraTransaction.new
  end

  describe "rnt_tax" do
    it "should return @myrnttax variable" do
      expect(@avalara_transaction.rnt_tax).to eq(@rnt_tax)
    end
  end
  describe "amount" do
    it "should return @myrnttax variable" do
      expect(@avalara_transaction.amount).to eq(@rnt_tax)
    end
  end
end
