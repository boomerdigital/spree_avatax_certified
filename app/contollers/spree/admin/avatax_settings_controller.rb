module Spree
  module Admin
    class AvataxSettingsController < Spree::Admin::BaseController

      respond_to :html

      def show
      end

      def get_file_content_txt_svc
        data = open("log/tax_svc.txt")

        send_data data.read, filename: "tax_svc.txt", type: "application/text", disposition: 'inline', stream: 'true'
      end

      def get_file_content_post_avatax
        data = open("log/post_order_to_avalara.txt")

        send_data data.read, filename: "post_order_to_avalara.txt", type: "application/text", disposition: 'inline', stream: 'true'
      end

      def get_file_content_avatax_ord
        data = open("log/avalara_order.txt")

        send_data data.read, filename: "avalara_order.txt", type: "application/text", disposition: 'inline', stream: 'true'
      end

      def ping_my_service
        mytax = TaxSvc.new( Spree::Config.avatax_account, Spree::Config.avatax_license_key, Spree::Config.avatax_endpoint)
        pingResult = mytax.ping
        if pingResult["ResultCode"] == "Success"
          flash[:success] = "Ping Successful"

        else
          flash[:error] = "Ping Error"
        end

        respond_to do |format|
          format.js
        end
      end

      def download_txt_svc
        send_file 'log/tax_svc.txt', :type=>"application/text"
      end

      def update
        origin = params[:address]
        taxpref = params[:settings]

        Spree::Config.avatax_origin = { :Address1 =>  origin[:avatax_address1],
          :Address2 => origin[:avatax_address2],
          :City => origin[:avatax_city],
          :Region => origin[:avatax_region],
          :Zip5 => origin[:avatax_zip5],
          :Zip4 => origin[:avatax_zip4],
          :Country => origin[:avatax_country]}.to_json

        Spree::Config.avatax_api_username = taxpref[:avatax_api_username]
        Spree::Config.avatax_api_password = taxpref[:avatax_api_password]
        Spree::Config.avatax_endpoint = taxpref[:avatax_endpoint]
        Spree::Config.avatax_account = taxpref[:avatax_account]
        Spree::Config.avatax_servicepathtax = taxpref[:avatax_servicepathtax]
        Spree::Config.avatax_servicepathaddress = taxpref[:avatax_servicepathaddress]
        Spree::Config.avatax_license_key = taxpref[:avatax_license_key]
        Spree::Config.avatax_iseligible = taxpref[:avatax_iseligible]
        Spree::Config.avatax_company_code =taxpref[:avatax_company_code]
        Spree::Config.avatax_customer_code =taxpref[:avatax_customer_code]
        Spree::Config.avatax_client_version = taxpref[:avatax_client_version]

        respond_to do |format|
          format.html {
            redirect_to admin_avatax_settings_path
          }
        end
      end
    end
  end
end
