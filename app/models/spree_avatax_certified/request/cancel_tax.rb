module SpreeAvataxCertified
  module Request
    class CancelTax < SpreeAvataxCertified::Request::Base
      def generate
        @request = {
          CompanyCode: company_code,
          DocType: @doc_type,
          DocCode: order.number,
          CancelCode: 'DocVoided'
        }
      end
    end
  end
end
