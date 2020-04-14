module SpreeAvataxCertified
  module Response
    class GetTax < SpreeAvataxCertified::Response::Base
      alias :tax_result :result

      def description
        'Get Tax'
      end
    end
  end
end
