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
          CustomerCode: customer_code,
          CompanyCode: company_code,
          CustomerUsageType: order.customer_usage_type,
          ExemptionNo: order.user.try(:exemption_number),
          Client:  avatax_client_version,
          ReferenceCode: order.number,
          DetailLevel: 'Tax',
          CurrencyCode: order.currency
        }
      end

       # If there is a vat id, set BusinessIdentificationNo
      def check_vat_id
        if !business_id_no.blank?
          @request[:BusinessIdentificationNo] = business_id_no
        end
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

      def avatax_client_version
        AVATAX_CLIENT_VERSION || 'a0o33000004FH8l'
      end
    end
  end
end
