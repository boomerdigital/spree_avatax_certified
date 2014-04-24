module Spree
  module Admin
    class AvalaraUseCodeItemsController < Spree::Admin::ResourceController

      respond_to  :html

      def index
        if params[:ids]
          @use_codes = AvalaraUseCodeItem.where(:id => params[:ids])
        elsif params[:q]
          @use_codes = AvalaraUseCodeItem.ransack(:use_code_cont => params[:q]).result
        else
          @use_codes = AvalaraUseCodeItem.all
        end
        respond_to do |format|
          format.html
          format.json { render json: @use_codes }
        end

      end
      def show
        @use_codes = AvalaraUseCodeItem.find(params[:id])
      end
    end
  end
end