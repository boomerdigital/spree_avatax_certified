require_relative '~/app/models/spree/avalara/TaxSvc'
module Spree
#module AvataxHelper
  def  ping_my_service
    mytax = TaxSvc.new( Spree::Config.avatax_account || AvalaraYettings['account'],Spree::Config.avatax_license_key || AvalaraYettings['license_key'],Spree::Config.avatax_endpoint || AvalaraYettings['endpoint'])
    pingResult = mytax.Ping
    if pingResult["ResultCode"] != "Success"
      "Success"
    end
  end
end
