class SpreeAvataxCertified::Response::CancelTax < SpreeAvataxCertified::Response::Base
  alias :tax_result :result

  def initialize(result)
    @result = result['CancelTaxResult']
  end

  def description
    'Cancel Tax'
  end
end
