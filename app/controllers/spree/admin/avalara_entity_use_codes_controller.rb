module Spree
  module Admin
    class AvalaraEntityUseCodesController < Spree::Admin::ResourceController
      respond_to :html

      def index
        @use_codes = Spree::AvalaraEntityUseCode.all

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
