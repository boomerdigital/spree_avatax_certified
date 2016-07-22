require 'spec_helper'

describe Spree::Refund, type: :model do

  it { should have_one :avalara_transaction }

  subject(:order) do
    order = create(:shipped_order)
    Spree::AvalaraTransaction.create(order: order)
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

  describe "#avalara_capture" do
    it "should recieve avalara_capture and return hash" do
      expect(refund).to receive(:avalara_capture).and_return(Hash)
      refund.avalara_capture
    end
    it "should response with Hash object" do
      expect(refund.avalara_capture).to be_kind_of(Hash)
    end
    context 'error' do
      it 'should raise error' do
        Spree::AvalaraTransaction.find_by_order_id(refund.payment.order.id).destroy
        expect(refund.avalara_capture).to eq('error in avalara capture refund')
      end
    end
  end

  describe "#avalara_capture_finalize" do
    it "should recieve avalara_capture_finalize and return hash" do
      expect(refund).to receive(:avalara_capture_finalize).and_return(Hash)
      refund.save
    end
    it "should response with Hash object" do
      expect(refund.avalara_capture_finalize).to be_kind_of(Hash)
    end
  end


  context 'full refund' do
    it 'returns correct tax calculations' do
      clothing_tax_rate = create(:clothing_tax_rate)
      order = create(:avalara_order, tax_category: clothing_tax_rate.tax_category)
      order.update_attributes(state: 'complete', completed_at: Time.now)
      payment = create(:payment, order: order, amount: order.total.to_f)
      refund = build(:refund, payment: payment, amount: order.total.to_f)

      response = refund.avalara_capture

      expect(response['TotalAmount'].to_f.abs).to eq(order.total - order.additional_tax_total)
      expect(response['TotalTax'].to_f.abs).to eq(order.additional_tax_total)
    end
  end
end
