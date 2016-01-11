module SpreeAvataxCertified
  class Response
    def initialize(response_hash)
      @response = response_hash
    end

    def success?
      @response['ResultCode'] == 'Success' || @response[:result_code] == 'Success'
    end

    def total_tax
      @response['TotalTax'] || @response[:total_tax]
    end

    def tax_lines
      @response['TaxLines'] || @response[:tax_lines][:tax_line]
    end
  end
end
