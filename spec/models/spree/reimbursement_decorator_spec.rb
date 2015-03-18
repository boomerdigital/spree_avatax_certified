require 'spec_helper'

describe Spree::Reimbursement, type: :model do

  let(:order) {FactoryGirl.create(:shipped_order)}
  let(:stock_location) {create(:stock_location)}
  let(:return_authorization_reason) { create(:return_authorization_reason)}
  let!(:default_refund_reason) { Spree::RefundReason.find_or_create_by!(name: Spree::RefundReason::RETURN_PROCESSING_REASON, mutable: false) }

  before :each do
    MyConfigPreferences.set_preferences
    @order = FactoryGirl.create(:shipped_order)
    payment = create(:payment, amount: @order.total, order: @order, state: 'completed')
    return_authorization = Spree::ReturnAuthorization.create(:order => @order, :stock_location => stock_location, :reason => return_authorization_reason)
    @inventory_unit = @order.shipments.first.inventory_units.first
    return_item = return_authorization.return_items.create(inventory_unit: @inventory_unit)
    customer_return = return_authorization.return_items.first.build_customer_return(stock_location: stock_location)
    customer_return.return_items << return_item
    customer_return.save!
    @customer_return = customer_return
  end
  let(:reimbursement) { create(:reimbursement, customer_return: @customer_return, order: @order, return_items: [@customer_return.return_items.first])}

  describe "#avalara_eligible" do
    it "should return true" do
      expect(reimbursement.avalara_eligible).to eq(true)
    end
  end
  describe "#avalara_lookup" do
    it "should return lookup_avatax" do
      expect(reimbursement.avalara_lookup).to eq(:lookup_avatax)
    end
    it "creates new avalara_transaction" do
      expect{reimbursement}.to change{Spree::AvalaraTransaction.count}.by(1)
    end
  end
  describe "#avalara_capture" do
    it "creates new avalara_transaction" do
      expect{reimbursement.avalara_capture}.to change{Spree::AvalaraTransaction.count}.by(1)
    end
  end
  context "finalized" do
    subject { reimbursement.perform! }
    describe "#avalara_capture_finalize" do
      it "creates new avalara_transaction" do
        expect{subject}.to change{Spree::AvalaraTransaction.count}.by(1)
      end
    end

    describe "#pending" do
      it "returns inital state of authorized" do
        expect(reimbursement.reimbursement_status).to eq("pending")
      end
    end

    describe "#reimbursed" do
      it "should update reimbursement state" do
        expect{subject}.to change{reimbursement.reimbursement_status}.to eq("reimbursed")
      end
    end
  end
end
