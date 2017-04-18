require 'spec_helper'


RSpec.describe SpreeAvataxCertified::Request::CancelTax do
  let(:order) { Spree::Order.new }
  subject { described_class.new(order, doc_type: 'SalesInvoice') }

  describe '#generate' do
    it 'DocType has value of SalesInvoice' do
      expect(subject.generate[:DocType]).to eq('SalesInvoice')
    end
  end
end
