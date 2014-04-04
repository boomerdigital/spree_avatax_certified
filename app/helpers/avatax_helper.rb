require_relative '~/app/models/spree/avalara/TaxSvc'
Spree::BaseHelper.module_eval do

  alias_method :ping_my_service

  def  ping_my_service
    mytax = TaxSvc.new( Spree::Config.avatax_account || AvalaraYettings['account'],Spree::Config.avatax_license_key || AvalaraYettings['license_key'],Spree::Config.avatax_endpoint || AvalaraYettings['endpoint'])
    pingResult = mytax.Ping
    if pingResult["ResultCode"] == "Success"
      flash[:success] = "Ping Successful"
    else
      flash[:error] = "Ping Error"
    end

    respond_to do |format|
      format.js
    end
  end
end
