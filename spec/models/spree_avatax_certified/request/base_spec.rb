require 'spec_helper'


RSpec.describe SpreeAvataxCertified::Request::Base do
  let(:order) { Spree::Order.new }
  subject { described_class.new(order) }

  describe '#generate' do
    it 'raises error' do
      expect{ subject.generate }.to raise_error('Method needs to be implemented in subclass.')
    end
  end
end
