require 'spec_helper'

describe Spree::Admin::AvalaraUseCodeItemsController do
  let(:avalara_use_code_item) { FactoryGirl.create(:use_code) }

  stub_authorization!

  before :each do
    DatabaseCleaner.clean
  end

  describe "#index" do
    subject { spree_get :index }

    it { should be_success }
  end

  describe "#show" do
    subject { spree_get :show, id: avalara_use_code_item.id }

    it { should be_success }
  end

  describe "#new" do
    subject {spree_get :new }

    it { should be_success }
  end

  describe "#edit" do
    subject {spree_get :edit, id: avalara_use_code_item.id}

    it { should be_success }
  end

  describe "#update" do
    let(:params) do
      {
        id: avalara_use_code_item.to_param,
        avalara_use_code_item: {
          use_code: "55",
        }
      }
    end
    subject { spree_put :update, params }

    it { should redirect_to(spree.admin_avalara_use_code_items_path) }
    it "expect @use_code to eq the use_code being updated" do
      assigns(:avalara_use_code_item).should eq(@use_code)
    end

    it "should update use_code" do
      expect{subject}.to change { avalara_use_code_item.reload.use_code }.from('A').to('55')
    end
  end
end
