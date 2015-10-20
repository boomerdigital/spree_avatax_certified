require 'spec_helper'

describe Spree::Refund, type: :model do

  it { should have_one :avalara_transaction }

  subject(:order) do
    order = create(:shipped_order)
    Spree::AvalaraTransaction.create(order: order)
    order.line_items.first.tax_category.update_attributes(tax_code: 'PC030000')
    order.reload
  end

  let(:amount) { 10.0 }
  let(:amount_in_cents) { amount * 100 }

  let(:authorization) { generate(:refund_transaction_id) }

  let(:payment_amount) { amount*2 }
  let(:payment_method) { create(:credit_card_payment_method) }
  let(:payment) { create(:payment, amount: payment_amount, payment_method: payment_method, order: order) }

  let(:refund_reason) { create(:refund_reason) }

  let(:gateway_response) {
    ActiveMerchant::Billing::Response.new(
      gateway_response_success,
      gateway_response_message,
      gateway_response_params,
      gateway_response_options
    )
  }
  let(:gateway_response_success) { true }
  let(:gateway_response_message) { "" }
  let(:gateway_response_params) { {} }
  let(:gateway_response_options) { {} }

  let(:reimbursement) { create(:reimbursement) }

  let(:refund) {Spree::Refund.new(payment: payment, amount: BigDecimal.new(10), reason: refund_reason, transaction_id: nil, reimbursement: reimbursement)}
  before do
    MyConfigPreferences.set_preferences
    allow(payment.payment_method)
    .to receive(:credit)
    .with(amount_in_cents, payment.source, payment.transaction_id, {originator: an_instance_of(Spree::Refund)})
    .and_return(gateway_response)
    order.reload
  end


  context "transaction id exists" do
    let(:transaction_id) { "12kfjas0" }
    subject { create(:refund, payment: payment, amount: amount, reason: refund_reason, transaction_id: transaction_id) }
    describe "#avalara_eligible?" do
      it "should return true" do
        expect(subject.avalara_eligible?).to eq(true)
      end
    end
  end

  describe "#avalara_eligible?" do
    let(:transaction_id) { "12kfjas0" }
    subject { create(:refund, payment: payment, amount: amount, reason: refund_reason, transaction_id: transaction_id) }
    it "should return true" do
      expect(subject.avalara_eligible?).to eq(true)
    end
  end

  describe "#avalara_capture_finalize" do
    it "should recieve avalara_capture_finalize and return hash" do
      expect(refund).to receive(:avalara_capture_finalize).and_return(Hash)
      refund.save
    end
  end
end
