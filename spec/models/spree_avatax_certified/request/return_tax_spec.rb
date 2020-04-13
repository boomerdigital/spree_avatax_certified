require 'spec_helper'

RSpec.describe SpreeAvataxCertified::Request::ReturnTax do
  subject { described_class.new(order, commit: true, doc_type: 'ReturnOrder', refund: refund) }

  let(:order) { create(:shipped_order) }
  let(:refund) { create(:refund, payment: order.payments.first, reimbursement: create(:reimbursement)) }

  describe '#generate' do
    it 'creates a hash' do
      expect(subject.generate).to be_kind_of Hash
    end

    it 'Commit has value of true' do
      expect(subject.generate[:createTransactionModel][:commit]).to be true
    end

    it 'has ReferenceCode from base_tax_hash' do
      expect(subject.generate[:createTransactionModel][:referenceCode]).to eq(order.number)
    end

    it 'has TaxOverride' do
      expect(subject.generate[:createTransactionModel][:taxOverride]).to be_present
    end
  end
end
