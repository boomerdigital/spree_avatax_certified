module Spree
  class Admin::AvataxSettingsController < Admin::BaseController

    respond_to  :html

    def show
    end

    def  ping_my_service
      mytax = TaxSvc.new( Spree::Config.avatax_account || AvalaraYettings['account'],Spree::Config.avatax_license_key || AvalaraYettings['license_key'],Spree::Config.avatax_endpoint || AvalaraYettings['endpoint'])
      pingResult = mytax.Ping
      if pingResult["ResultCode"] == "Success"
        flash[:success] = "Ping Successful"
      #flash[:success] = 'Message sent!'
      else
        flash[:error] ="Ping Error"
      end

      respond_to do |format|
        format.js
      end
    end

    def update
      origin = params[:address]
      taxpref = params[:settings]
      Spree::Config.avatax_origin = {   :Address1 =>  origin[:avatax_address1],
                                          :Address2 => origin[:avatax_address2],
                                          :City => origin[:avatax_city],
                                          :State => origin[:avatax_state],
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


      respond_to do |format|
        format.html {
          redirect_to admin_avatax_settings_path
        }
      end
    end
  end
end