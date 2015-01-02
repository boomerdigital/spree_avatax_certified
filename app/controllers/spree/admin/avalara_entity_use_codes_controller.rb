module Spree
  module Admin
    class AvalaraEntityUseCodesController < Spree::Admin::ResourceController
      respond_to :html

      def index
        if params[:ids]
          @use_codes = Spree::AvalaraEntityUseCode.where(:id => params[:ids])
        elsif params[:q]
          @use_codes = Spree::AvalaraEntityUseCode.ransack(:use_code_cont => params[:q]).result
        else
          @use_codes = Spree::AvalaraEntityUseCode.all
        end
        respond_to do |format|
          format.html
          format.json { render json: @use_codes }
        end
      end

      def show
        @use_code = Spree::AvalaraEntityUseCode.find(params[:id])
      end
    end
  end
end
