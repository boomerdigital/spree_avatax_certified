require 'spec_helper'
module Spree
  module Admin
    describe AvalaraUseCodeItemsController, :type => :controller do
      stub_authorization!
      before :each do
        DatabaseCleaner.clean
      end
      describe "#index" do
        subject { spree_get :index }

        it 'should be successful' do
          expect(subject).to be_success
        end
      end
      describe "#show" do
        use_code = Spree::AvalaraUseCodeItem.create(use_code: "A", use_code_description: "Federal government")
        subject { spree_get :show, id: use_code.id }
        it "shows the use code of the id parameter" do
          expect(subject).to be_success
        end
      end
      describe "#new" do
        subject {spree_get :new}
        it "blah" do
          expect(subject).to be_success
        end
      end
      describe "#edit" do
        use_code = Spree::AvalaraUseCodeItem.create(use_code: "A", use_code_description: "Federal government")
        subject {spree_get :edit, id: use_code.id}
        it "shows edit form" do
          expect(subject).to be_success
        end
      end

      describe "#update" do
          use_code = FactoryGirl.create(:use_code)
          params = {id: use_code.id, use_code: "55"}
          subject {spree_put :update, params}
        it "should redirect to index path" do
          expect(subject).to redirect_to(spree.admin_avalara_use_code_items_path)
        end
        it "expect @use_code to eq the use_code being updated" do
          assigns(:use_code).should eq(@use_code)
        end
        it "should update use_code" do
          expect { subject }.to change { use_code.reload.use_code }.from('A').to('55')
        end
      end
    end
  end
end
