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
end