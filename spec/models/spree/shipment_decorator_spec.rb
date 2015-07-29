require 'spec_helper'

describe Spree::Shipment, type: :model do

  let(:shipment) { create(:shipment) }

  describe '#avatax_cache_key' do
    it 'should respond with a cache key' do
      expected_response = "Spree::Shipment-#{shipment.id}-#{shipment.cost}-#{shipment.stock_location.cache_key}-#{shipment.promo_total}"

      expect(shipment.avatax_cache_key).to eq(expected_response)
    end
  end

  describe "#avatax_line_code" do
    it 'should equal FR' do
      expect(shipment.avatax_line_code).to eq('FR')
    end
  end
end
