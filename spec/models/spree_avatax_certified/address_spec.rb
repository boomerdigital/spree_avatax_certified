require 'spec_helper'

describe SpreeAvataxCertified::Address, :type => :model do
  let(:address){ FactoryGirl.create(:address) }
  let(:order) { FactoryGirl.create(:order_with_line_items) }

  before do
    @address_lines = SpreeAvataxCertified::Address.new(order)
    Spree::Config.avatax_address_validation = true
    @real_address = address.clone
    @real_address.update_attributes(city: 'Tuscaloosa', address1: '220 Paul W Bryant Dr')
  end

 describe "#validate" do
    it "validates address with success" do
      result = @address_lines.validate(@real_address)
      expect(@address_lines.validate(@real_address)["ResultCode"]).to eq("Success")
    end

    it "does not validate address because of incorrect address" do
      result = @address_lines.validate(address)
      expect(@address_lines.validate(address)["ResultCode"]).to eq("Error")
    end

    it "does not validate when config settings are false" do
      Spree::Config.avatax_address_validation = false
      result = @address_lines.validate(address)
      expect(@address_lines.validate(address)).to eq("Address validation disabled")
    end
 end
end