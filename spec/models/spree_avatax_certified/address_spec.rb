require 'spec_helper'

describe SpreeAvataxCertified::Address, :type => :model do
  let(:country){ FactoryGirl.create(:country) }
  let(:address){ FactoryGirl.create(:address) }
  let(:order) { FactoryGirl.create(:order_with_line_items) }

  before do
    Spree::Config.avatax_address_validation = true
    order.ship_address.update_attributes(city: 'Tuscaloosa', address1: '220 Paul W Bryant Dr')
  end

  let(:address_lines) { SpreeAvataxCertified::Address.new(order) }

  describe '#initialize' do
    it 'should have order' do
      expect(address_lines.order).to eq(order)
    end
    it 'should have addresses be an array' do
      expect(address_lines.addresses).to be_kind_of(Array)
    end
  end

  describe '#build_addresses' do
    it 'receives origin_address' do
        expect(address_lines).to receive(:origin_address)
        address_lines.build_addresses
    end
    it 'receives order_ship_address' do
        expect(address_lines).to receive(:order_ship_address)
        address_lines.build_addresses
    end
    it 'receives origin_ship_addresses' do
        expect(address_lines).to receive(:origin_ship_addresses)
        address_lines.build_addresses
    end
  end

  describe '#origin_address' do
    it 'returns an array' do
      expect(address_lines.origin_address).to be_kind_of(Array)
    end

    it 'has the origin address return a hash' do
      expect(address_lines.origin_address[0]).to be_kind_of(Hash)
    end
  end

  describe '#order_ship_address' do
    it 'returns an array' do
      expect(address_lines.order_ship_address).to be_kind_of(Array)
    end

    it 'has the origin address return a hash' do
      expect(address_lines.order_ship_address[0]).to be_kind_of(Hash)
    end
  end

  describe "#validate" do
    it "validates address with success" do
      result = address_lines.validate
      expect(address_lines.validate["ResultCode"]).to eq("Success")
    end

    it "does not validate when config settings are false" do
      Spree::Config.avatax_address_validation = false
      result = address_lines.validate
      expect(address_lines.validate).to eq("Address validation disabled")
    end
  end

  describe '#country_enabled?' do
    it 'returns true if the current country is enabled' do
      expect(address_lines.country_enabled?).to be_truthy
    end
  end
end
