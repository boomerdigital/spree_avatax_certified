require 'spec_helper'

RSpec.describe SpreeAvataxCertified::Request::ReturnTax do
  let(:order) { create(:shipped_order) }
  let(:refund) { create(:refund, payment: order.payments.first, reimbursement: create(:reimbursement)) }

  subject { described_class.new(order, commit: false, doc_type: 'ReturnOrder', refund: refund) }

  describe '#generate' do
    it 'creates a hash' do
      expect(subject.generate).to be_kind_of Hash
    end

    it 'Commit has value of false' do
      expect(subject.generate[:Commit]).to be false
    end

    it 'has ReferenceCode from base_tax_hash' do
      expect(subject.generate[:ReferenceCode]).to eq(order.number)
    end

    it 'has TaxOverride' do
      expect(subject.generate[:TaxOverride]).to be_present
    end

    it 'calls check_vat_id' do
      expect(subject).to receive(:check_vat_id)
      subject.generate
    end
  end
end
