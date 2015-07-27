require 'spec_helper'

describe Spree::Shipment, type: :model do

  let(:shipment) { create(:shipment) }

  describe '#avatax_cache_key' do
    it 'should respond with a cache key' do
      expected_response = "Spree::Shipment-#{shipment.id}-#{shipment.cost}-#{shipment.stock_location.cache_key}"

      expect(shipment.avatax_cache_key).to eq(expected_response)
    end
  end
end
