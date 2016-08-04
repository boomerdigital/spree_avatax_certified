module Spree
  module Admin
    class AvataxSettingsController < Spree::Admin::BaseController

      respond_to :html

      def show
      end

      def get_file_txt_tax_svc
        send_file "#{Rails.root}/log/tax_svc.log"
      end

      def get_file_post_order_to_avalara
        send_file "#{Rails.root}/log/post_order_to_avalara.log"
      end

      def get_file_avalara_order
        send_file "#{Rails.root}/log/avalara_order.log"
      end

      def erase_data
        File.open("log/#{params['log_name']}.log", 'w') {}

        render nothing: true
      end

      def ping_my_service
        mytax = TaxSvc.new
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
          Address1:  origin[:avatax_address1],
          Address2: origin[:avatax_address2],
          City: origin[:avatax_city],
          Region: origin[:avatax_region],
          Zip5: origin[:avatax_zip5],
          Zip4: origin[:avatax_zip4],
          Country: origin[:avatax_country]
        }.to_json

        Spree::Config.avatax_api_username = pref[:avatax_api_username]
        Spree::Config.avatax_api_password = pref[:avatax_api_password]
        Spree::Config.avatax_endpoint = pref[:avatax_endpoint]
        Spree::Config.avatax_account = pref[:avatax_account]
        Spree::Config.avatax_license_key = pref[:avatax_license_key]
        Spree::Config.avatax_vat_id = pref[:avatax_vat_id]
        Spree::Config.avatax_log = pref[:avatax_log]
        Spree::Config.avatax_address_validation = pref[:avatax_address_validation]
        Spree::Config.avatax_address_validation_enabled_countries = pref[:avatax_address_validation_enabled_countries]
        Spree::Config.avatax_tax_calculation = pref[:avatax_tax_calculation]
        Spree::Config.avatax_document_commit = pref[:avatax_document_commit]
        Spree::Config.avatax_company_code = pref[:avatax_company_code]

        respond_to do |format|
          format.html {
            redirect_to admin_avatax_settings_path
          }
        end
      end
    end
  end
end
