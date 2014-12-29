require 'spec_helper'

describe Spree::Reimbursement, type: :model do

  it { should have_one :avalara_transaction }

  let(:stock_location) {create(:stock_location)}
  let(:return_authorization_reason) { create(:return_authorization_reason)}
  let!(:default_refund_reason) { Spree::RefundReason.find_or_create_by!(name: Spree::RefundReason::RETURN_PROCESSING_REASON, mutable: false) }

  before :each do
    MyConfigPreferences.set_preferences
    @order = FactoryGirl.create(:completed_order_with_totals)
    @order.shipments.each do |shipment|
      shipment.inventory_units.update_all state: 'shipped'
      shipment.update_column('state', 'shipped')
    end
    @order.reload
    payment = create(:payment, amount: @order.total, order: @order, state: 'completed')
    return_authorization = Spree::ReturnAuthorization.create(:order => @order, :stock_location => stock_location, :reason => return_authorization_reason)
    @order.line_items.each do |line_item|
      line_item.tax_category.update_attributes(name: "Clothing", description: "PC030000")
    end
    @inventory_unit = @order.shipments.first.inventory_units.first
    return_item = return_authorization.return_items.create(inventory_unit: @inventory_unit)
    customer_return = return_authorization.return_items.first.build_customer_return(stock_location: stock_location)
    customer_return.return_items << return_item
    customer_return.save!
    reimbursement = create(:reimbursement, customer_return: customer_return, order: @order, return_items: [customer_return.return_items.first])
  end

  describe "#avalara_eligible" do
    it "should return true" do
      expect(@order.avalara_transaction.reimbursement.avalara_eligible).to eq(true)
    end
  end
  describe "#avalara_lookup" do
    it "should return lookup_avatax" do
      expect(@order.avalara_transaction.reimbursement.avalara_lookup).to eq(:lookup_avatax)
    end
    it "creates new avalara_transaction" do
      expect{@order.avalara_transaction.reimbursement.avalara_lookup}.to change{Spree::AvalaraTransaction.count}.by(1)
    end
  end
  describe "#avalara_capture" do
    it "should response with Spree::Adjustment object" do
      expect(@order.avalara_transaction.reimbursement.avalara_capture).to be_kind_of(Spree::Adjustment)
    end
    it "creates new avalara_transaction" do
      expect{@order.avalara_transaction.reimbursement.avalara_capture}.to change{Spree::AvalaraTransaction.count}.by(1)
    end
  end
  describe "#avalara_capture_finalize" do
    it "should response with Spree::Adjustment object" do
      expect(@order.avalara_transaction.reimbursement.avalara_capture_finalize).to be_kind_of(Spree::Adjustment)
    end
    it "creates new avalara_transaction" do
      expect{@order.avalara_transaction.reimbursement.avalara_capture_finalize}.to change{Spree::AvalaraTransaction.count}.by(1)
    end
  end

  describe "#pending" do
    it "returns inital state of authorized" do
      expect(@order.avalara_transaction.reimbursement.reimbursement_status).to eq("pending")
    end
  end

  describe "#reimbursed" do
    it "should update reimbursement state" do
      @order.avalara_transaction.reimbursement.perform!
      expect(@order.avalara_transaction.reimbursement.reimbursement_status).to eq("reimbursed")
    end
    it "should receive avalara_capture_finalize" do
      expect(@order.avalara_transaction.reimbursement).to receive(:avalara_capture_finalize)
      @order.avalara_transaction.reimbursement.perform!
    end
  end
end