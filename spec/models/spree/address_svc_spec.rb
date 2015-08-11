require 'spec_helper'

describe AddressSvc, type: :model do
  let(:country) { create(:country) }
  let(:state) { create(:state) }
  let(:address) { FactoryGirl.create(:address) }

  before :each do
    MyConfigPreferences.set_preferences
    @address_svc = AddressSvc.new
    Spree::Config.avatax_address_validation = true
    @real_address = address.clone
    @real_address.update_attributes(city: 'Tuscaloosa', address1: '220 Paul W Bryant Dr')
  end

  describe '#validate' do
    it 'validates address with success' do
      result = @address_svc.validate(@real_address)
      expect(@address_svc.validate(@real_address)['ResultCode']).to eq('Success')
    end

    it 'does not validate address because of incorrect address' do
      result = @address_svc.validate(address)
      expect(@address_svc.validate(address)).to eq('error in address validation')
    end

    it 'does not validate when config settings are false' do
      Spree::Config.avatax_address_validation = false
      result = @address_svc.validate(address)
      expect(@address_svc.validate(address)).to eq('Address validation disabled')
    end
  end

  describe '#country_enabled?' do
    it 'returns true if current_country is in address' do
      expect(@address_svc.country_enabled?(Spree::Country.find(address[:country_id]))).to eq(true)
    end
  end
end
