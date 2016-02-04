require 'spec_helper'

describe SpreeAvataxCertified::Response, type: :model do

  let(:completed_request_hash) { attributes_for(:request_hash) }
  let(:incomplete_request_hash) { attributes_for(:request_hash, Lines: nil) }

  let(:successful_response) {
    result = TaxSvc.new.get_tax(completed_request_hash)
    SpreeAvataxCertified::Response.new(result)
  }

  let(:error_response) {
    result = TaxSvc.new.get_tax(incomplete_request_hash)
    SpreeAvataxCertified::Response.new(result)
  }

  context 'completed request' do
    describe '#success?' do
      it 'responses true' do
        expect(successful_response.success?).to be_truthy
      end
    end

    describe '#error?' do
      it 'responses false' do
        expect(successful_response.error?).to be_falsey
      end
    end

    describe '#total_tax' do
      it 'is a string' do
        expect(successful_response.total_tax).to be_kind_of(String)
      end
    end
    describe '#tax_lines' do
      it 'is an array' do
        expect(successful_response.tax_lines).to be_kind_of(Array)
      end
    end
    describe '#tax_result' do
      it 'is a hash' do
        expect(successful_response.tax_result).to be_kind_of(Hash)
      end
    end
  end

  context 'incomplete request' do
    describe '#success?' do
      it 'returns false' do
        expect(error_response.success?).to be_falsey
      end
    end

    describe '#error?' do
      it 'returns true' do
        expect(error_response.error?).to be_truthy
      end
    end

    describe '#tax_result' do
      it 'is a hash' do
        expect(error_response.tax_result).to be_kind_of(Hash)
      end
    end
  end
end
