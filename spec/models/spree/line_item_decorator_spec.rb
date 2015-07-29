require 'spec_helper'

describe Spree::LineItem, type: :model do

  let(:order) { create :order_with_line_items, line_items_count: 1 }
  let(:line_item) { order.line_items.first }

  describe "#to_hash" do
    it "should create hash of line item information" do
      expect(line_item.to_hash).to be_kind_of(Hash)
    end
    it "should have index of 1" do
      response = line_item.to_hash
      expect(response['Index']).to eq(1)
    end
  end

  describe '#avatax_cache_key' do
    it 'should respond with a cache key' do
      expected_response = "Spree::LineItem-#{line_item.id}-#{line_item.quantity}-#{line_item.price}-#{line_item.promo_total}"

      expect(line_item.avatax_cache_key).to eq(expected_response)
    end
  end

  describe "#avatax_line_code" do
    it 'should equal LI' do
      expect(line_item.avatax_line_code).to eq('LI')
    end
  end
end
