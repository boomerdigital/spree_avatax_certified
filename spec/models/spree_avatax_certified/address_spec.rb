require 'spec_helper'

describe SpreeAvataxCertified::Address, :type => :model do
  let(:address){ FactoryGirl.create(:address) }
  let(:order) { FactoryGirl.create(:order_with_line_items) }

  before do
    Spree::Config.avatax_address_validation = true
    order.ship_address.update_attributes(city: 'Tuscaloosa', address1: '220 Paul W Bryant Dr')
  end

  let(:address_lines) { SpreeAvataxCertified::Address.new(order) }

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
end
