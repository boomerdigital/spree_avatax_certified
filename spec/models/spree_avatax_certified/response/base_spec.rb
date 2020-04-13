require 'spec_helper'

RSpec.describe SpreeAvataxCertified::Response::Base do
  subject { described_class.new(response_hash) }

  describe '#error?' do
    let(:response_hash) { attributes_for(:response_hash_error).stringify_keys }

    it 'returns true with ResultCode is not Success' do
      expect(subject.error?).to be true
    end
  end
end
