module SpreeAvataxCertified
  module Response
    class CancelTax < SpreeAvataxCertified::Response::Base
      alias :tax_result :result

      def description
        'Cancel Tax'
      end

      def success?
        result['status'] == 'Cancelled'
      end
    end
  end
end
