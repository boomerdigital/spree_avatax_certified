module SpreeAvataxCertified
  module Response
    class Base
      attr_accessor :result
      # To Do
      # 1. Create way to display errors cleanly

      def initialize(result)
        @result = result
      end

      def success?
        result['ResultCode'] == 'Success'
      end

      def error?
        !success? rescue true
      end

      def description
        raise 'Method needs to be implemented in subclass.'
      end
    end
  end
end
