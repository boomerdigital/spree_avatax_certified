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

    context 'Destination Address contents' do
      let(:dest_address_line) { address_lines.addresses[1] }

      it 'AddressCode' do
        expect(dest_address_line[:AddressCode]).to eq('Dest')
      end

      it 'Line1' do
        expect(dest_address_line[:Line1]).to eq(order.ship_address.address1)
      end

      it 'City' do
        expect(dest_address_line[:City]).to eq(order.ship_address.city)
      end

      it 'Region' do
        expect(dest_address_line[:Region]).to eq(order.ship_address.state_name)
      end

      it 'Country' do
        expect(dest_address_line[:Country]).to eq(order.ship_address.country.iso)
      end

      it 'PostalCode' do
        expect(dest_address_line[:PostalCode]).to eq(order.ship_address.zipcode)
      end
    end

    context 'Stock location address contents' do
      let(:stock_address_line) { address_lines.addresses.last }
      let(:stock_location) { order.shipments.first.stock_location }

      it 'AddressCode' do
        expect(stock_address_line[:AddressCode]).to eq(stock_location.id.to_s)
      end

      it 'Line1' do
        expect(stock_address_line[:Line1]).to eq(stock_location.address1)
      end

      it 'City' do
        expect(stock_address_line[:City]).to eq(stock_location.city)
      end

      it 'Region' do
        expect(stock_address_line[:Region]).to eq(stock_location.state_name)
      end

      it 'Country' do
        expect(stock_address_line[:Country]).to eq(stock_location.country.iso)
      end

      it 'PostalCode' do
        expect(stock_address_line[:PostalCode]).to eq(stock_location.zipcode)
      end
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

    context 'with no ship_address connected to the order' do
      before do
        order.ship_address = nil
      end
      it 'returns false if there is no @ship_address' do
        expect(address_lines.country_enabled?).to be_falsey
      end
    end
  end
end
