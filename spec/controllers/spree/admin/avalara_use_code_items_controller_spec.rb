require 'spec_helper'

describe Spree::AvalaraUseCodeItemsController do
  describe "#index" do
    it "shows all use code items" do
      get :index
      its(:response) { should have_http_status 200 }
      its(:response) { should_not have_http_status 401 }
    end
  end
  context "#show" do
    # let(:use_code) {FactoryGirl.create(:use_code)}
    it "shows the use code of the id parameter" do
      use_code = Spree::AvalaraUseCodeItem.create(use_code: "A", use_code_description: "Federal government")
      get :show, id: use_code.id
      expect(assigns(:use_code)).to eq(use_code)

    end
  end
end