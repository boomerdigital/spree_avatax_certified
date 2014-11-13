require 'spec_helper'

describe AddressSvc, :type => :model do
  let(:address){FactoryGirl.create(:address)}

 describe "#validate" do
    it "validates address with success" do
      real_address = Spree::Address.create!(firstname: "Allison", lastname: "Reilly", address1: "220 Paul W Bryant Dr", city: "Tuscaloosa", zipcode: "35401", phone: "9733492462", state_name: "Alabama", state_id: 1, country_id: 1)
      p real_address
      address_svc = AddressSvc.new
      result = address_svc.validate(real_address)
      expect(address_svc.validate(real_address)).to eq("Success")
    end

    it "does not validate address because of incorrect address" do
      address_svc = AddressSvc.new
      result = address_svc.validate(address)
      expect(address_svc.validate(address)["ResultCode"]).to eq("Error")
    end
 end
end