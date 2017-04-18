module SpreeAvataxCertified
  module Response
    class CancelTax < SpreeAvataxCertified::Response::Base
      alias :tax_result :result

      def initialize(result)
        @result = result['CancelTaxResult']
      end

      def description
        'Cancel Tax'
      end
    end
  end
end
