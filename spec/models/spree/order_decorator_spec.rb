require 'spec_helper'

describe Spree::Order, type: :model do

  it { should have_one :avalara_transaction }

  let(:order) {FactoryGirl.create(:order_with_line_items)}
  let(:completed_order) {create(:completed_order_with_totals)}
  let(:variant) { create(:variant) }

  describe "#avalara_eligible?" do
    it "should return true" do
      expect(order.avalara_eligible?).to eq(true)
    end
  end

  describe "#cancel_avalara" do

    before do
      completed_order.avalara_capture_finalize
      @response = completed_order.cancel_avalara
    end

    it 'should be successful' do
      expect(@response["ResultCode"]).to eq("Success")
    end

    it "should return hash" do
      expect(@response).to be_kind_of(Hash)
    end

    it 'should receive cancel_order when cancel_avalara is called' do
      expect(completed_order.avalara_transaction).to receive(:cancel_order)
      completed_order.cancel_avalara
    end

    context 'state machine event cancel' do
      it 'should recieve cancel_avalara when event cancel is called' do
        expect(completed_order).to receive(:cancel_avalara)
        completed_order.cancel!
      end

      it 'avalara_transaction should recieve cancel_order when event cancel is called' do
        expect(completed_order.avalara_transaction).to receive(:cancel_order)
        completed_order.cancel!
      end
    end
  end

  describe "#avalara_capture" do
    it "should response with Hash object" do
      expect(order.avalara_capture).to be_kind_of(Hash)
    end
    it "creates new avalara_transaction" do
      expect{order.avalara_capture}.to change{Spree::AvalaraTransaction.count}.by(1)
    end
    it 'should have a ResultCode of success' do
      expect(order.avalara_capture['ResultCode']).to eq('Success')
    end
  end

  describe "#avalara_capture_finalize" do
    it "should response with Hash object" do
      expect(order.avalara_capture_finalize).to be_kind_of(Hash)
    end
    it "creates new avalara_transaction" do
      expect{order.avalara_capture_finalize}.to change{Spree::AvalaraTransaction.count}.by(1)
    end
    it 'should have a ResultCode of success' do
      expect(order.avalara_capture_finalize['ResultCode']).to eq('Success')
    end

    context 'commit on completed at date' do
      before do
        completed_order.update_attributes(completed_at: 5.days.ago)
      end

      it 'has a docdate of completed at date' do
        response = completed_order.avalara_capture_finalize
        expect(response['DocDate']).to eq(5.days.ago.strftime('%F'))
      end
    end
  end


  describe "#adjust_avalara" do
    context 'committed order' do
      let(:adjust_order) {
        order.avalara_capture_finalize
        order
      }
      it "should response with Hash object" do
        expect(adjust_order.adjust_avalara).to be_kind_of(Hash)
      end
      it 'should have a ResultCode of success' do
        expect(adjust_order.adjust_avalara[:result_code]).to eq('Success')
      end
    end
  end

  describe '#avatax_cache_key' do
    it 'should respond with a cache key' do
      expected_response = "Spree::Order-#{order.number}-#{order.promo_total}"

      expect(order.avatax_cache_key).to eq(expected_response)
    end
  end
end
