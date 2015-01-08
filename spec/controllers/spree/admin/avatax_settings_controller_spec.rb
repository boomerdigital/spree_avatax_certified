require 'spec_helper'

module Spree
  module Admin
    describe AvataxSettingsController, :type => :controller do
      stub_authorization!
      describe "/avatax_settings" do
        subject { spree_get :show }
        it { should be_success }
      end
    end
  end
end
