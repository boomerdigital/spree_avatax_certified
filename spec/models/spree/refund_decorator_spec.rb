require 'spec_helper'

RSpec.describe Spree::Refund, :vcr do

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


  describe '#avalara_tax_enabled?' do
    it 'should return true' do
      expect(Spree::Refund.new.avalara_tax_enabled?).to eq(true)
    end
  end

  describe '#avalara_capture_finalize' do
    subject do
      refund.save
    end

    it 'should recieve avalara_capture_finalize and return hash' do
      expect(refund).to receive(:avalara_capture_finalize).and_return(Hash)
      subject
    end
  end


  context 'full refund' do
    let(:order) { create(:completed_avalara_order, shipment_cost: 10) }
    let(:refund) { build(:refund, payment: order.payments.first, amount: order.total.to_f) }

    subject do
      order.reload
      refund.avalara_capture_finalize
    end

    it 'returns correct tax calculations' do
      expect(subject['totalAmount'].to_f.abs).to eq(order.total - order.additional_tax_total)
      expect(subject['totalTax'].to_f.abs).to eq(order.additional_tax_total)
    end
  end
end
