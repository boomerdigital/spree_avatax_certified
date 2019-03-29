require 'spec_helper'

RSpec.describe Spree::Payment, :vcr do
  subject(:order) do
    order = FactoryBot.create(:completed_order_with_totals)
    Spree::AvalaraTransaction.create(order: order)
    order
  end

  let(:gateway) do
    gateway = Spree::Gateway::Bogus.create(active: true, name: 'Bogus')
    allow(gateway).to receive_messages :environment => 'test'
    allow(gateway).to receive_messages source_required: true
    gateway
  end

  let(:card) { create :credit_card }

  let(:payment) do
    payment = Spree::Payment.new
    payment.source = card
    payment.order = order
    payment.payment_method = gateway
    payment.amount = 5
    payment
  end


  let(:amount_in_cents) { (payment.amount * 100).round }

  let!(:success_response) do
    double('success_response', :success? => true,
           :authorization => '123',
           :avs_result => { 'code' => 'avs-code' },
           :cvv_result => { 'code' => 'cvv-code', 'message' => "CVV Result"})
  end

  let(:failed_response) { double('gateway_response', :success? => false) }

  before(:each) do
    allow(payment.log_entries).to receive(:create!)
  end


  describe "#purchase!" do
    subject do
      order.avalara_capture_finalize
      payment.purchase!
    end

    it "receive avalara_finalize" do
      expect(payment).to receive(:avalara_finalize)
      subject
    end
  end

  describe '#avalara_finalize' do
    subject do
      order.avalara_capture_finalize
      payment.avalara_finalize
    end

    it 'should update the amount to be the order total' do
      payment.update_attributes(amount: 5)
      initial_amount = payment.amount

      subject

      expect(payment.amount).not_to eq(initial_amount)
    end
  end

  describe "#void_transaction!" do
    it "receive cancel_avalara" do
      expect(payment).to receive(:cancel_avalara)
      payment.void_transaction!
    end
  end

  describe '#cancel_avalara' do
    it 'should receive cancel order on avalara transaction' do
      expect(payment.order.avalara_transaction).to receive(:cancel_order)
      payment.cancel_avalara
    end

    context 'uncommitted order' do
      subject do
        payment.cancel_avalara
      end

      it 'should recieve error message' do
        expect(subject['error']).to be_present
      end
    end

    context 'committed order' do
      subject do
        order.avalara_capture_finalize
        payment.cancel_avalara
      end

      it 'should receive result of success' do
        expect(subject['status']).to eq('Cancelled')
      end
    end
  end
end
