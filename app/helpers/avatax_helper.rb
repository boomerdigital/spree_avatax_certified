Spree::BaseHelper.module_eval do

  # alias_method :ping_my_service, :get_file_content

  # def  ping_my_service
  #   mytax = TaxSvc.new( Spree::Config.avatax_account, Spree::Config.avatax_license_key, Spree::Config.avatax_endpoint)
  #   pingResult = mytax.ping
  #   if pingResult["ResultCode"] == "Success"
  #     flash[:success] = "Ping Successful"
  #   else
  #     flash[:error] = "Ping Error"
  #   end

  #   respond_to do |format|
  #     format.js
  #   end
  # end

  # def get_file_content(file_name="tax_svc.txt")
  #   data = File.open(file_name, "rb"){|io| a = a + io.read}
  #   respond_to do |format|
  #     format.js
  #   end
  # end
end
