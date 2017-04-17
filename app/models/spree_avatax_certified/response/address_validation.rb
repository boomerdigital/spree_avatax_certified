module SpreeAvataxCertified
  module Response
    class AddressValidation < SpreeAvataxCertified::Response::Base
      alias :validation_result :result

      def initialize(result)
        @result = JSON.parse(result)
      end

      def description
        'Address Validation'
      end
    end
  end
end
