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
        File.open(params['path'], 'w') {}
      end

      def ping_my_service
        mytax = TaxSvc.new
        pingResult = mytax.ping
        if pingResult['ResultCode'] == 'Success'
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
        taxpref = params[:settings]

        Spree::Config.avatax_origin = {
          :Address1 =>  origin[:avatax_address1],
          :Address2 => origin[:avatax_address2],
          :City => origin[:avatax_city],
          :Region => origin[:avatax_region],
          :Zip5 => origin[:avatax_zip5],
          :Zip4 => origin[:avatax_zip4],
          :Country => origin[:avatax_country]
        }.to_json

        Spree::Config.avatax_api_username = taxpref[:avatax_api_username]
        Spree::Config.avatax_api_password = taxpref[:avatax_api_password]
        Spree::Config.avatax_endpoint = taxpref[:avatax_endpoint]
        Spree::Config.avatax_account = taxpref[:avatax_account]
        Spree::Config.avatax_license_key = taxpref[:avatax_license_key]
        Spree::Config.avatax_iseligible = taxpref[:avatax_iseligible]
        Spree::Config.avatax_log = taxpref[:avatax_log]
        Spree::Config.avatax_address_validation = taxpref[:avatax_address_validation]
        Spree::Config.avatax_address_validation_enabled_countries = taxpref[:avatax_address_validation_enabled_countries]
        Spree::Config.avatax_tax_calculation = taxpref[:avatax_tax_calculation]
        Spree::Config.avatax_document_commit = taxpref[:avatax_document_commit]
        Spree::Config.avatax_company_code =taxpref[:avatax_company_code]

        respond_to do |format|
          format.html {
            redirect_to admin_avatax_settings_path
          }
        end
      end
    end
  end
end
