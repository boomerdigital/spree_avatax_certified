require 'spec_helper'

RSpec.describe SpreeAvataxCertified::Request::GetTax, :vcr do
  subject { described_class.new(order, commit: false, doc_type: 'SalesOrder') }

  let!(:order) { create(:avalara_order, line_items_count: 2) }

  describe '#generate' do
    it 'creates a hash' do
      expect(subject.generate).to be_kind_of Hash
    end

    it 'Commit has value of false' do
      expect(subject.generate[:createTransactionModel][:commit]).to be false
    end

    it 'has ReferenceCode from base_tax_hash' do
      expect(subject.generate[:createTransactionModel][:referenceCode]).to eq(order.number)
    end
  end
end
