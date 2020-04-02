require 'spec_helper'

RSpec.describe Spree::Admin::AvataxSettingsController, type: :controller do
  stub_authorization!

  describe "/avatax_settings" do
    subject { spree_get :show }
    it { is_expected.to be_successful }
  end

  describe "/avatax_settings/edit" do
    subject { spree_get :edit }
    it { is_expected.to be_successful }
  end

  describe '/avatax_settings/download_avatax_log' do
    before { File.new("#{Rails.root}/log/avatax.log", 'w') }
    after { File.delete("#{Rails.root}/log/avatax.log") }

    subject { spree_get :download_avatax_log }
    it { is_expected.to be_successful }
  end

  describe '/avatax_settings/erase_data' do
    it 'erases the log' do
      Dir.mkdir('log') unless Dir.exist?('log')
      file = File.open("log/avatax.log", 'w') { |f| f.write('Hyah!') }

      expect(File.read('log/avatax.log')).to eq('Hyah!')

      spree_get :erase_data

      expect(File.read('log/avatax.log')).to eq('')
    end
  end

  describe '/avatax_settings/ping_my_service' do
    it 'flashes message' do
      subject { spree_get :ping_my_service }
      response.should be_successful
      flash.should_not be_nil
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
