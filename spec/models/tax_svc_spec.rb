require 'spec_helper'

RSpec.describe TaxSvc, :vcr do
  let(:taxsvc) { TaxSvc.new }
  let(:request_hash) { build(:request_hash) }

  describe '#get_tax' do
    subject { taxsvc.get_tax(request_hash) }

    it 'gets tax when all credentials are there' do
      expect(subject.tax_result['totalTax']).to be_present
    end

    context 'error response' do
      before do
        Spree::Config.avatax_raise_exceptions = false
      end

      it 'returns error when no params are given' do
        expect(taxsvc.get_tax({}).tax_result.keys.first).to eq('error')
      end

      it 'returns error when taxCode is too long' do
        req = build(:request_hash)
        req[:createTransactionModel][:lines][0][:taxCode] = 'sdfsdfsdfsdfsdfsdfsdfsdfsdfsdfsdfsdfsdfsdf'
        result = taxsvc.get_tax(req).tax_result

        expect(result.keys.first).to eq('error')
      end

      it 'returns error when no lines are given' do
        req = build(:request_hash)
        req[:createTransactionModel][:lines] = []
        result = taxsvc.get_tax(req).tax_result

        expect(result.keys.first).to eq('error')
      end
    end
  end

  describe '#cancel_tax' do
    let(:request_hash) {
      req = build(:request_hash)
      req[:createTransactionModel][:commit] = true
      req[:createTransactionModel][:date] = Date.today.strftime('%F')
      req[:createTransactionModel][:type] = 'SalesInvoice'
      req[:createTransactionModel][:code] = "testcancel-#{rand(0..100000)}"
      req
    }

    it 'should raise error if no transaction_code is passed' do
      expect { taxsvc.cancel_tax(nil) }.to raise_error
    end

    it 'respond with success' do
      success_res = taxsvc.get_tax(request_hash)
      result = taxsvc.cancel_tax(request_hash[:createTransactionModel][:code])

      expect(result.tax_result['status']).to eq('Cancelled')
    end
  end

  describe '#ping' do
    subject do
      VCR.use_cassette('ping', allow_playback_repeats: true) do
        taxsvc.ping
      end
    end

    it 'should return successful' do
      expect(subject.success?).to be_truthy
    end
  end
end

