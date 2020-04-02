module Spree
  module Admin
    class AvataxSettingsController < Spree::Admin::BaseController

      respond_to :html

      def show
      end

      def download_avatax_log
        send_file "#{Rails.root}/log/avatax.log"
      end

      def erase_data
        File.open("log/avatax.log", 'w') {}

        head :ok
      end

      def ping_my_service
        mytax = Spree::TaxSvc.new
        ping_result = mytax.ping
        if ping_result['ResultCode'] == 'Success'
          flash[:success] = 'Ping Successful'
        else
          flash[:error] = 'Ping Error'
        end

        respond_to do |format|
          format.js
        end
      end

      def update
        origin = params[:address]
        pref = params[:settings]

        Spree::Config.avatax_origin = {
          Address1:  origin['avatax_address1'],
          Address2: origin['avatax_address2'],
          City: origin['avatax_city'],
          Region: origin['avatax_region'],
          Zip5: origin['avatax_zip5'],
          Zip4: origin['avatax_zip4'],
          Country: origin['avatax_country']
        }.to_json

        Spree::Config.avatax_api_username = pref['avatax_api_username']
        Spree::Config.avatax_api_password = pref['avatax_api_password']
        Spree::Config.avatax_endpoint = pref['avatax_endpoint']
        Spree::Config.avatax_account = pref['avatax_account']
        Spree::Config.avatax_license_key = pref['avatax_license_key']
        Spree::Config.avatax_log = pref['avatax_log'] || false
        Spree::Config.avatax_log_to_stdout = pref['avatax_log_to_stdout'] || false
        Spree::Config.avatax_address_validation = pref['avatax_address_validation'] || false
        Spree::Config.avatax_tax_calculation = pref['avatax_tax_calculation'] || false
        Spree::Config.avatax_document_commit = pref['avatax_document_commit'] || false
        Spree::Config.avatax_address_validation_enabled_countries = pref['avatax_address_validation_enabled_countries']
        Spree::Config.avatax_company_code = pref['avatax_company_code']

        respond_to do |format|
          format.html {
            redirect_to admin_avatax_settings_path
          }
        end
      end
    end
  end
end
