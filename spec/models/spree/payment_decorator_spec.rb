require 'spec_helper'

describe Spree::Payment, :type => :model do
  subject(:order) do
    order = FactoryGirl.create(:completed_order_with_totals)
    Spree::AvalaraTransaction.create(order: order)
    order
  end

  let(:gateway) do
    gateway = Spree::Gateway::Bogus.new(:environment => 'test', :active => true)
    allow(gateway).to receive_messages :source_required => true
    gateway
  end

  let(:card) do
    Spree::CreditCard.create!(
      number: "4111111111111111",
      month: "12",
      year: Time.now.year + 1,
      verification_value: "123",
      name: "Name",
      imported: false
    )
  end

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
    it "receive avalara_finalize" do
      expect(payment).to receive(:avalara_finalize)
      payment.purchase!
    end
  end

  describe '#avalara_finalize' do
    before do
      order.update_attributes(additional_tax_total: 1.to_f)
    end

    it 'should update the amount to be the order total' do
      initial_amount = payment.amount
      payment.avalara_finalize
      expect(payment.amount).not_to eq(initial_amount)
    end

    it 'should receive avalara_capture_finalize on order' do
      expect(payment.order).to receive(:avalara_capture_finalize)
      payment.avalara_finalize
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
      it 'should recieve error message' do
        response = payment.cancel_avalara
        expect(response['ResultCode']).to eq('Error')
      end
    end

    context 'committed order' do
      it 'should receive result of success' do
        payment.avalara_finalize
        response = payment.cancel_avalara
        expect(response['ResultCode']).to eq('Success')
      end
    end
  end
end
