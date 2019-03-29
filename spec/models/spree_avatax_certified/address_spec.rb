require 'spec_helper'

describe SpreeAvataxCertified::Address, :type => :model do
  let(:address){ build(:address) }
  let(:order) { build(:order_with_line_items, ship_address: address) }

  before do
    Spree::Config.avatax_address_validation = true
  end

  let(:address_lines) { SpreeAvataxCertified::Address.new(order) }

  describe '#initialize' do
    it 'should have order' do
      expect(address_lines.order).to eq(order)
    end
    it 'should have addresses be a Hash' do
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
    before do
      address_lines.build_addresses
    end
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
    subject do
      address_lines.validate
    end

    it "validates address with success" do
      expect(subject.success?).to be_truthy
    end

    it "does not validate when config settings are false" do
      Spree::Config.avatax_address_validation = false

      expect(subject).to eq("Address validation disabled")
    end

    context 'error' do
      let(:order) { create(:order_with_line_items) }

      subject do
        order.ship_address.update_attributes(city: nil, zipcode: nil)
        address_lines.validate
      end

      it 'fails when information is incorrect' do
        expect(subject.error?).to be_truthy
      end

      it 'raises exception if preference is set to true' do
        Spree::Config.avatax_raise_exceptions = true

        expect { subject }.to raise_exception(SpreeAvataxCertified::RequestError)
      end
    end
  end
end
