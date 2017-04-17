require 'spec_helper'

RSpec.describe SpreeAvataxCertified::Request::GetTax do
  let(:order) { create(:avalara_order, line_items_count: 2) }
  subject { described_class.new(order, commit: false, doc_type: 'SalesOrder') }

  before do
    VCR.use_cassette('order_capture', allow_playback_repeats: true) do
      order
    end
  end

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

    it 'calls check_vat_id' do
      expect(subject).to receive(:check_vat_id)
      subject.generate
    end
  end
end
