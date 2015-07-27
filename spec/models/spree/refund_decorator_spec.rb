require 'spec_helper'

describe Spree::Refund, type: :model do

  it { should have_one :avalara_transaction }

  let(:order) {FactoryGirl.create(:shipped_order)}
  let(:amount) { 10.0 }
  let(:amount_in_cents) { amount * 100 }

  let(:authorization) { generate(:refund_transaction_id) }

  let(:payment) { create(:payment, amount: payment_amount, payment_method: payment_method, order: order) }
  let(:payment_amount) { amount*2 }
  let(:payment_method) { create(:credit_card_payment_method) }

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


  before do
    MyConfigPreferences.set_preferences
    allow(payment.payment_method)
    .to receive(:credit)
    .with(amount_in_cents, payment.source, payment.transaction_id, {originator: an_instance_of(Spree::Refund)})
    .and_return(gateway_response)
  end

  let(:refund) {Spree::Refund.create(payment: payment, amount: BigDecimal.new(10), reason: refund_reason, transaction_id: nil)}

  context "transaction id exists" do
    let(:transaction_id) { "12kfjas0" }
    subject { create(:refund, payment: payment, amount: amount, reason: refund_reason, transaction_id: transaction_id) }
    describe "#avalara_eligible" do
      it "should return true" do
        expect(subject.avalara_eligible).to eq(true)
      end
    end
  end

  describe "#avalara_eligible" do
    it "should return true" do
      expect(refund.avalara_eligible).to eq(true)
    end
  end

  describe "#avalara_lookup" do
    it "should return lookup_avatax" do
      expect(refund.avalara_lookup).to eq(:lookup_avatax)
    end
    it "creates new avalara_transaction" do
      expect{refund}.to change{Spree::AvalaraTransaction.count}.by(1)
    end
  end

  describe "#avalara_capture" do
    it "creates new avalara_transaction" do
      expect{refund.avalara_capture}.to change{Spree::AvalaraTransaction.count}.by(1)
    end
  end
end
