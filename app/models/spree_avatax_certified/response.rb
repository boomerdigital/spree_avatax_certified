module SpreeAvataxCertified
  class Response
    def initialize(response)
      @response = response
    end

    def success?
      return false if error?
      @response['ResultCode'] == 'Success' || @response[:result_code] == 'Success'
    end

    def error?
      @response == 'error in Tax' || @response['ResultCode'] == 'Error' || @response[:result_code] == 'Error'
    end

    def total_tax
      @response['TotalTax'] || @response[:total_tax]
    end

    def tax_lines
      @response['TaxLines'] || @response[:tax_lines][:tax_line]
    end

    def tax_result
      if error?
        { TotalTax: '0.00' }
      elsif success?
        @response
      end
    end
  end
end
