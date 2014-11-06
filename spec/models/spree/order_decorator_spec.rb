require 'spec_helper'

describe Spree::Order, type: :model do
  MyConfigPreferences.set_preferences

  it { should have_one :avalara_transaction }

  before :each do
      @order = FactoryGirl.create(:order)
  end

  describe "#avalara_eligible" do
    it "should return true" do
      expect(@order.avalara_eligible).to eq(true)
    end
  end
  describe "#avalara_capture" do
    it "should response with Spree::Adjustment object" do
      expect(@order.avalara_capture).to be_kind_of(Spree::Adjustment)
    end
  end
end