require 'spec_helper'

describe Spree::Payment, :type => :model do
  subject(:order) do
    order = FactoryGirl.create(:completed_order_with_totals)
    order.line_items.first.tax_category.update_attributes(name: "Clothing", description: "PC030000")
    order.avalara_capture_finalize
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
    it "should call purchase on the gateway with the payment amount" do
      expect(payment).to receive(:avalara_finalize)
      payment.purchase!
    end
  end

  describe "#void_transaction!" do
      it "should call payment_gateway.void with the payment's response_code" do
        expect(payment).to receive(:cancel_avalara)
        payment.void_transaction!
    end
  end
end
