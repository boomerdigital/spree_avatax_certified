require 'spec_helper'

describe SpreeAvataxCertified::Address, :type => :model do
  let(:address){ build(:address) }
  let(:order) { build(:avalara_order, ship_address: address) }

  before do
    Spree::Config.avatax_address_validation = true
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
      let(:order) { create(:order_with_line_items, ship_address: address) }
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

  describe '#validate' do
    context 'on success' do
      subject do
        VCR.use_cassette('address_validation_success', allow_playback_repeats: true) do
          address_lines.validate
        end
      end
      it 'validates address with success' do
        expect(subject['ResultCode']).to eq('Success')
      end
    end

    context 'on failure' do
      let(:address){ Spree::Address.new(country: create(:country)) }
      let(:order) { build(:avalara_order, ship_address: address) }
      let(:address_lines) { SpreeAvataxCertified::Address.new(order)  }

      subject do
        VCR.use_cassette('address_validation_failure', allow_playback_repeats: true) do
          address_lines.validate
        end
      end

      it 'validates address with error' do
        expect(subject['ResultCode']).to eq('Error')
      end
    end

    it 'does not validate when config settings are false' do
      Spree::Config.avatax_address_validation = false
      result = address_lines.validate
      expect(address_lines.validate).to eq('Address validation disabled')
    end
  end


  describe 'multiple stock locations' do
    let(:stock_loc_2) { create(:stock_location) }
    let(:var1) {
      variant = create(:variant)
      variant.stock_items.destroy_all
      variant.stock_items.create(stock_location_id: Spree::StockLocation.first.id, backorderable: true)
      variant
    }
    let(:var2) {
      variant = create(:variant)
      variant.stock_items.destroy_all
      variant.stock_items.create(stock_location_id: stock_loc_2.id, backorderable: true)
      variant
    }
    let(:line_item1) { create(:line_item, variant: var1) }
    let(:line_item2) { create(:line_item, variant: var2) }
    let(:order) { create(:order_with_line_items, line_items: [line_item1, line_item2]) }
    let(:result_addresses) do
      addresses = order.shipments.map { |s| s.stock_location.address1 }
      addresses << order.ship_address.address1
      addresses << JSON.parse(Spree::Config.avatax_origin)['Address1']
      addresses
    end

    before do
      order.create_proposed_shipments
      order.reload
      order.shipments.reload
    end

    it 'should have correct addresses' do
      addresses = SpreeAvataxCertified::Address.new(order).addresses.map { |a| a[:Line1] }

      expect(addresses).to match_array result_addresses
    end
  end
end
