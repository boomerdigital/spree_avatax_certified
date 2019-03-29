require 'spec_helper'

describe Spree::Order, :vcr do

  let(:order) { build(:avalara_order, ship_address: build(:address)) }
  let(:avalara_order) { create(:avalara_order) }
  let(:completed_order) { create(:completed_avalara_order) }

  describe "#avalara_tax_enabled?" do
    it "should return true" do
      expect(Spree::Order.new.avalara_tax_enabled?).to eq(true)
    end
  end

  describe '#cancel_avalara' do
    subject do
      avalara_order.avalara_capture_finalize
      avalara_order.cancel_avalara
    end

    it 'return a hash with a status of cancelled' do
      expect(subject['status']).to eq('Cancelled')
      expect(subject).to be_kind_of(Hash)
    end

    it 'should receive cancel_order when cancel_avalara is called' do
      expect(avalara_order.avalara_transaction).to receive(:cancel_order)
      subject
    end

    context 'state machine event cancel' do
      it 'should recieve cancel_avalara when event cancel is called' do
        expect(completed_order).to receive(:cancel_avalara)
        completed_order.cancel!
      end
    end

    context 'error' do
      subject do
        avalara_order.cancel_avalara
      end

      it 'should receive error key' do
        expect(subject['error']).to be_present
      end

      it 'should raise exception if preference is enabled' do
        Spree::Config.avatax_raise_exceptions = true

        expect{ subject }.to raise_exception(SpreeAvataxCertified::RequestError)
      end
    end
  end

  describe "#avalara_capture" do
    subject do
      avalara_order.avalara_capture
    end

    it "should response with Hash object" do
      expect(subject).to be_kind_of(Hash)
    end
    it "creates new avalara_transaction" do
      expect{subject}.to change{Spree::AvalaraTransaction.count}.by(1)
    end
    it 'should have key totalTax' do
      expect(subject['totalTax']).to be_present
    end
  end

  describe "#avalara_capture_finalize" do

    subject do
      avalara_order.avalara_capture_finalize
    end

    it "should response with Hash object" do
      expect(subject).to be_kind_of(Hash)
    end

    it 'should have key totalTax' do
      expect(subject['totalTax']).to be_present
    end

    # Spec fails when using VCR since dates are involved.

    # context 'commit on completed at date' do
    #   before do
    #     completed_order.update_attributes(completed_at: 5.days.ago)
    #   end

    #   it 'has a docdate of completed at date' do
    #     response = completed_order.avalara_capture_finalize
    #     expect(response['DocDate']).to eq(5.days.ago.strftime('%F'))
    #   end
    # end
  end

  describe '#avatax_cache_key' do
    it 'should respond with a cache key' do
      expected_response = "Spree::Order-#{order.number}-#{order.promo_total}"

      expect(order.avatax_cache_key).to eq(expected_response)
    end
  end

  describe '#customer_usage_type' do
    let(:use_code) { build(:avalara_entity_use_code) }

    before do
      order.user.update_attributes(avalara_entity_use_code: use_code)
    end

    it 'should respond with user usage type' do
      expect(order.customer_usage_type).to eq('A')
    end
    it 'should respond with blank string if no user' do
      order.update_attributes(user: nil)
      expect(order.customer_usage_type).to eq('')
    end
  end

  describe '#validate_ship_address' do
    before do
      Spree::Config.avatax_address_validation = true
    end
    it 'should return the response if validation is success' do
      response = order.validate_ship_address

      expect(response['error']).to_not be_present
    end

    it 'should return the response if refuse checkout on address validation is disabled' do
      Spree::Config.avatax_refuse_checkout_address_validation_error = false
      response = order.validate_ship_address

      expect(response['error']).to_not be_present
    end

    context 'validation failed' do
      it 'should return false' do
        Spree::Config.avatax_refuse_checkout_address_validation_error = true
        order.ship_address.update_attributes(zipcode: nil, city: nil, address1: nil)
        response = order.validate_ship_address

        expect(response).to eq(false)
      end

      it 'raise exceptions if raise_exceptions preference is enabled' do
        Spree::Config.avatax_raise_exceptions = true
        order.ship_address.update_attributes(zipcode: nil, city: nil, address1: nil)

        expect{ order.validate_ship_address }.to raise_exception(SpreeAvataxCertified::RequestError)
      end
    end

  end

  describe '#address_validation_enabled?' do
    it 'should return false if ship address is nil' do
      order.ship_address = nil

      expect(order.address_validation_enabled?).to be_falsey
    end

    it 'returns true if preference is true and country validation is enabled' do
      Spree::Config.avatax_address_validation = true
      Spree::Config.avatax_address_validation_enabled_countries = ['United States', 'Canada']

      expect(order.address_validation_enabled?).to be_truthy
    end

    it 'returns false if address validation preference is false' do
      Spree::Config.avatax_address_validation = false

      expect(order.address_validation_enabled?).to be_falsey
    end

    it 'returns false if enabled country is not present' do
      Spree::Config.avatax_address_validation_enabled_countries = ['Canada']

      expect(order.address_validation_enabled?).to be_falsey
    end
  end

  describe '#can_commit?' do
    it 'returns false when order is not complete' do
      expect(order.can_commit?).to be false
    end

    it 'returns true when order is completed and has a completed payment' do
      order = create(:order_ready_to_ship)
      expect(order.can_commit?).to be true
    end
  end
end
