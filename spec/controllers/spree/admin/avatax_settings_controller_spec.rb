require 'spec_helper'

module Spree
  module Admin
    describe AvataxSettingsController, type: :controller do
      stub_authorization!

      describe "/avatax_settings" do
        subject { spree_get :show }
        it { should be_success }
      end

      describe "/avatax_settings/edit" do
        subject { spree_get :edit }
        it { should be_success }
      end

      describe "/avatax_settings/get_file_post_order_to_avalara" do
        subject { spree_get :get_file_post_order_to_avalara }
        it { should be_success }
      end

      describe "/avatax_settings/get_file_txt_tax_svc" do
        AvataxHelper::AvataxLog.new('tax_svc', 'tax_service', 'call to tax service')
        subject { spree_get :get_file_txt_tax_svc }
        it { should be_success }
      end

      describe "/avatax_settings/get_file_avalara_order" do
        AvataxHelper::AvataxLog.new('avalara_order', 'order class', 'start order processing')
        subject { spree_get :get_file_avalara_order }
        it { should be_success }
      end

      describe '/avatax_settings/ping_my_service' do
        it 'flashes message' do
          subject { spree_get :ping_my_service }
          response.should be_success
          flash.should_not be_nil
        end
      end

      describe '/avatax_settings/erase_data' do
        it 'erases the log' do
          Dir.mkdir('log') unless Dir.exist?('log')
          file = File.open("log/test.log", 'w') { |f| f.write('Hyah!') }

          expect(File.read('log/test.log')).to eq('Hyah!')

          spree_get :erase_data, { log_name: 'test' }

          expect(File.read('log/test.log')).to eq('')
        end
      end

      describe "#update" do
        let(:params) do
          {
            address: {
              avatax_address1: 'test'
            },
            settings: {
              avatax_account: "123456789"
            }
          }
        end

        subject { spree_put :update, params }

        it { is_expected.to redirect_to(spree.admin_avatax_settings_path) }
      end
    end
  end
end
