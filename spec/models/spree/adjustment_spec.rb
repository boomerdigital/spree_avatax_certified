require 'spec_helper'

describe Spree::Adjustment, type: :model do
  let(:order) { create :order_with_line_items }
  let(:adjustment) { create(:adjustment, order: order) }

  describe '#avatax_cache_key' do
    it 'should respond with a cache key' do
      expected_response = "Spree::Adjustment-#{adjustment.id}-#{adjustment.amount}"

      expect(adjustment.avatax_cache_key).to eq(expected_response)
    end
  end
end
