require 'spec_helper'

describe TaxSvc, :type => :model do
  describe "initialize" do
    it "initializes with correct params" do
      taxsvc = TaxSvc.new(ENV['AVALARA_ACCOUNT'], ENV['AVALARA_LISENCE_KEY'], ENV['AVALARA_ENDPOINT'])
      expect(taxsvc.service_url).to eq("https://development.avalara.net")
    end
  end
end