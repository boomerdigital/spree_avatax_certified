module SpreeAvataxCertified
  module Response
    class AddressValidation < SpreeAvataxCertified::Response::Base
      def description
        'Address Validation'
      end

      def validated_address
        @validated_address ||= if success?
                                 result['validatedAddresses'][0]
                               else
                                 {}
        end
      end

      def messages
        @messages ||= result['messages']
      end

      def success?
        !failed?
      end

      def error?
        result['error'].present?
      end

      def failed?
        error? || messages_present? && messages.any? { |m| m['severity'] == 'Error' }
      end

      def messages_present?
        messages.present?
      end

      def detailed_messages
        if error?
          result['error']['details'].map { |m| m['description'] }
        elsif failed?
          messages.map { |m| m['details'] }
        else
          []
        end
      end

      def summary_messages
        if error?
          result['error']['details'].map { |m| m['message'] }
        elsif failed?
          messages.map { |m| m['summary'] }
        else
          []
        end
      end
    end
  end
end
