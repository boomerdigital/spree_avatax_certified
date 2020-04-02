require 'spec_helper'

RSpec.describe Spree::TaxSvc, :vcr do
  let(:taxsvc) { Spree::TaxSvc.new }
  let(:request_hash) { attributes_for(:request_hash) }

  describe '#get_tax' do
    subject { taxsvc.get_tax(request_hash) }

    it 'gets tax when all credentials are there' do
      expect(subject.tax_result['ResultCode']).to eq('Success')
    end

    context 'fails' do
      it 'fails when no params are given' do
        expect(taxsvc.get_tax({}).tax_result['ResultCode']).to eq('Error')
      end

      it 'responds with error when result code is not a success' do
        req = attributes_for(:request_hash)
        req[:Lines][0][:TaxCode] = 'sdfsdfsdfsdfsdfsdfsdfsdfsdfsdfsdfsdfsdfsdf'
        result = taxsvc.get_tax(req).tax_result

        expect(result['ResultCode']).to eq('Error')
      end

      it 'fails when no lines are given' do
        result = taxsvc.get_tax(attributes_for(:request_hash, Lines: [])).tax_result

        expect(result['ResultCode']).to eq('Error')
      end
    end
  end

  describe '#cancel_tax' do
    it 'should raise error' do
      result = taxsvc.cancel_tax({
        :CompanyCode=> '54321',
        :DocType => 'SalesInvoice',
        :CancelCode => 'DocVoided'
        })
      expect(result.tax_result['ResultCode']).to eq('Error')
    end

    it 'respond with success' do
      success_res = taxsvc.get_tax(request_hash)
      result = taxsvc.cancel_tax({
        :CompanyCode=> '54321',
        :DocType => 'SalesInvoice',
        :DocCode => request_hash[:DocCode],
        :CancelCode => 'DocVoided'
      })

      expect(result.tax_result['ResultCode']).to eq('Success')
    end
  end

  describe '#ping' do
    it 'should return estimate' do
      result = taxsvc.ping
      expect(result['ResultCode']).to eq('Success')
    end
  end
end

