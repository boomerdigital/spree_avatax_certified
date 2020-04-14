require 'spec_helper'

describe SpreeAvataxCertified::Address, :type => :model do
  let(:order) { build(:avalara_order) }

  before do
    Spree::Config.avatax_address_validation = true
  end

  let(:address_lines) { SpreeAvataxCertified::Address.new(order) }

  describe '#initialize' do
    it 'should have order' do
      expect(address_lines.order).to eq(order)
    end
    it 'should have addresses be a hash' do
      expect(address_lines.addresses).to be_kind_of(Hash)
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
  end

  describe '#origin_address' do
    it 'returns a hash with correct keys' do
      expect(address_lines.origin_address).to be_kind_of(Hash)
      expect(address_lines.origin_address[:line1]).to be_present
    end
  end

  describe '#order_ship_address' do
    it 'returns a Hash with correct keys' do
      expect(address_lines.order_ship_address).to be_kind_of(Hash)
      expect(address_lines.order_ship_address[:line1]).to be_present
    end
  end

  describe '#validate', :vcr do
    context 'on success' do
      subject do
        address_lines.validate
      end
      it 'validates address with success' do
        expect(subject).to be_success
      end

      it 'does not validate when config settings are false' do
        Spree::Config.avatax_address_validation = false

        expect(subject).to eq('Address validation disabled')
      end
    end

    context 'on failure' do
      subject do
        order.ship_address.update(city: nil, zipcode: nil)
        address_lines.validate
      end

      it 'validates address with error' do
        expect { subject }.to raise_exception(SpreeAvataxCertified::RequestError)
      end

      it 'raises exception if preference is set to true' do
        Spree::Config.avatax_raise_exceptions = true

        expect { subject }.to raise_exception(SpreeAvataxCertified::RequestError)
      end
    end

    it 'does not validate when config settings are false' do
      Spree::Config.avatax_address_validation = false
      result = address_lines.validate
      expect(address_lines.validate).to eq('Address validation disabled')
    end
  end
end
