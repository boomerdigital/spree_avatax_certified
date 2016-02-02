require 'spec_helper'

describe SpreeAvataxCertified::SoapApi, type: :model do
  let!(:soap) { SpreeAvataxCertified::SoapApi.new }

  describe '#ping' do
    it 'responds with a hash' do
      expect(soap.ping).to be_kind_of(Hash)
    end
    it 'responds successfully' do
      expect(soap.ping[:ping_response][:ping_result][:result_code]).to eq('Success')
    end
  end

  describe '#adjust_tax' do
    let(:taxsvc) { TaxSvc.new }
    code = rand(100000).to_s
    let(:request_hash) { attributes_for(:request_hash, Commit: true, DocType: 'SalesInvoice', DocCode: code, ReferenceCode: code) }

    before do
      taxsvc.get_tax(request_hash)
    end

    subject { soap.adjust_tax(request_hash) }
    it 'should return a hash' do
      expect(subject).to be_kind_of(Hash)
    end

    it 'should have result code equal success' do
      expect(subject[:adjust_tax_response][:adjust_tax_result][:result_code]).to eq('Success')
    end
  end
end
