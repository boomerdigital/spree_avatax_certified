require 'spec_helper'

describe Spree::ReturnAuthorization, type: :model do
  it { should have_one :avalara_transaction }
  subject(:user) { FactoryGirl.create(:user) }
  subject(:stock_location) { FactoryGirl.create(:stock_location) }

  subject(:order) do
    order = FactoryGirl.create(:shipped_order)
    Spree::AvalaraTransaction.find_or_create_by(order: order)
    order.reload
    order
  end

  subject(:return_authorization) { Spree::ReturnAuthorization.create(:order => order, :stock_location => stock_location) }

  before do
    @inventory_unit = order.shipments.first.inventory_units.first
    @variant = order.variants.first
  end

  describe "#avalara_eligible?" do
    it "should return true" do
      expect(return_authorization.avalara_eligible?).to eq(true)
    end
  end
  describe "#avalara_lookup" do
    it "should return lookup_avatax" do
      expect(return_authorization.avalara_lookup).to eq(:lookup_avatax)
    end
  end

  describe "#avalara_capture" do
    it "should response with Hash object" do
      expect(return_authorization.avalara_capture).to be_kind_of(Hash)
    end
    it 'should have avalara_transaction receive commit_avatax when called' do
      expect(return_authorization.order.avalara_transaction).to receive(:commit_avatax)
      return_authorization.avalara_capture
    end
  end

  describe "#authorized" do
    it "returns inital state of authorized" do
      expect(return_authorization.state).to eq("authorized")
    end
  end

  context "received" do
    before do
      return_authorization.inventory_units << @inventory_unit
      return_authorization.add_variant(@variant.id, 1)
      return_authorization.state = "authorized"
      allow(order).to receive(:update!)
    end

    it "should update order state" do
      return_authorization.receive!
      expect(return_authorization.state).to eq("received")
    end

    it "should receive avalara_capture_finalize" do
      expect(return_authorization).to receive(:avalara_capture_finalize)
      return_authorization.receive!
    end

    it 'avalara_transaction should receive commit_avatax_final when return auth is received' do
      expect(return_authorization.order.avalara_transaction).to receive(:commit_avatax_final)
      return_authorization.receive!
    end
  end
end
