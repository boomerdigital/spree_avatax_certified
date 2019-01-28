require 'spec_helper'

describe Spree::Order, :vcr do

  let(:order) {FactoryBot.create(:order_with_line_items)}
  let(:avalara_order) { create(:completed_order_with_totals) }
  let(:variant) { create(:variant) }

  describe '#avalara_tax_enabled?' do
    it 'should return true' do
      expect(Spree::Order.new.avalara_tax_enabled?).to eq(true)
    end
  end

  describe '#cancel_avalara' do
    subject do
      VCR.use_cassette('order_cancel', allow_playback_repeats: true) do
        avalara_order.avalara_capture_finalize
        avalara_order.cancel_avalara
      end
    end

    it 'should be successful' do
      expect(subject['ResultCode']).to eq('Success')
    end

    it 'should return hash' do
      expect(subject).to be_kind_of(Hash)
    end

    it 'should recieve cancel_avalara when event cancel is called' do
      expect(avalara_order).to receive(:cancel_avalara)
      subject
    end

    context 'state machine event cancel' do
      subject do
        VCR.use_cassette('order_cancel', allow_playback_repeats: true) do
          avalara_order.avalara_capture_finalize
          avalara_order.cancel!
        end
      end
      it 'should recieve cancel_avalara when event cancel is called' do
        expect(avalara_order).to receive(:cancel_avalara)
        subject
      end
    end
  end

  describe '#avalara_capture' do
    subject do
      VCR.use_cassette('order_capture', allow_playback_repeats: true) do
        avalara_order.avalara_capture
      end
    end

    it 'should response with Hash object' do
      expect(subject).to be_kind_of(Hash)
    end
    it 'creates new avalara_transaction' do
      expect{subject}.to change{Spree::AvalaraTransaction.count}.by(1)
    end
    it 'should have a ResultCode of success' do
      expect(subject['ResultCode']).to eq('Success')
    end
  end

  describe '#avalara_capture_finalize' do
    subject do
      VCR.use_cassette('order_capture_finalize', allow_playback_repeats: true) do
        avalara_order.avalara_capture_finalize
      end
    end

    it 'should response with Hash object' do
      expect(subject).to be_kind_of(Hash)
    end
    it 'creates new avalara_transaction' do
      expect{subject}.to change{Spree::AvalaraTransaction.count}.by(1)
    end
    it 'should have a ResultCode of success' do
      expect(subject['ResultCode']).to eq('Success')
    end

    # VCR makes this spec fail due to the date
    # context 'commit on completed at date' do
    #   before do
    #     avalara_order.update_attributes(completed_at: 5.days.ago)
    #   end

    #   it 'has a docdate of completed at date' do
    #     response = avalara_order.avalara_capture_finalize
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
    let(:use_code) { create(:avalara_entity_use_code) }

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
end
