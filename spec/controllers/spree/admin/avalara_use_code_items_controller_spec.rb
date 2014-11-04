require 'rails_helper'

describe Spree::Admin::AvalaraUseCodeItemsController do
  let(:use_code) { Spree::AvalaraUseCodeItem.create(use_code: "A", use_code_description: "Federal government") }

  stub_authorization!

  before :each do
    DatabaseCleaner.clean
  end

  describe "#index" do
    subject { spree_get :index }

    it { should be_success }
  end

  describe "#show" do
    subject { spree_get :show, id: use_code.id }

    it { should be_success }
  end

  describe "#new" do
    subject {spree_get :new}

    it { should be_success }
  end

  describe "#edit" do
    subject {spree_get :edit, id: use_code.id}

    it { should be_success }
  end

  describe "#update" do
    use_code = FactoryGirl.create(:use_code)
    params = { id: use_code.id, use_code: "55" }
    subject { spree_put :update, params }

    xit { should redirect_to(spree.admin_avalara_use_code_items_path) }

    xit "expect @use_code to eq the use_code being updated" do
      assigns(:use_code).should eq(@use_code)
    end

    xit "should update use_code" do
      expect(subject).to change { use_code.reload.use_code }.from('A').to('55')
    end
  end
end
