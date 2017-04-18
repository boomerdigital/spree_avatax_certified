module SpreeAvataxCertified
  module Request
    class GetTax < SpreeAvataxCertified::Request::Base
      def generate
        @request = {
          DocCode: order.number,
          DocDate: doc_date,
          Discount: order.all_adjustments.promotion.eligible.sum(:amount).abs.to_s,
          Commit: @commit,
          DocType: @doc_type ? @doc_type : 'SalesOrder',
          Addresses: address_lines,
          Lines: sales_lines
        }.merge(base_tax_hash)

        check_vat_id

        @request
      end

      protected

      def doc_date
        order.completed? ? order.completed_at.strftime('%F') : Date.today.strftime('%F')
      end
    end
  end
end
