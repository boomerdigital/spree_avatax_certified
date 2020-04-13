module SpreeAvataxCertified
  module Request
    class Base
      attr_reader :order, :request

      def initialize(order, opts={})
        @order = order
        @doc_type = opts[:doc_type]
        @commit = opts[:commit]
        @request = {}
      end

      def generate
        raise 'Method needs to be implemented in subclass.'
      end

      protected

      def base_tax_hash
        {
          customerCode: customer_code,
          companyCode: company_code,
          customerUsageType: order.customer_usage_type,
          exemptionNo: order.user.try(:exemption_number),
          referenceCode: order.number,
          currencyCode: order.currency,
          businessIdentificationNo: business_id_no
        }
      end

      def address_lines
        @address_lines ||= SpreeAvataxCertified::Address.new(order).addresses
      end

      def sales_lines
        @sales_lines ||= SpreeAvataxCertified::Line.new(order, @doc_type).lines
      end

      def company_code
        @company_code ||= Spree::Config.avatax_company_code
      end

      def business_id_no
        order.user.try(:vat_id)
      end

      def customer_code
        order.user ? order.user.id : order.email
      end
    end
  end
end
