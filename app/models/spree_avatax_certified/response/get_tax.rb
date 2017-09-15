class SpreeAvataxCertified::Response::GetTax < SpreeAvataxCertified::Response::Base
  alias :tax_result :result

  def description
    'Get Tax'
  end
end
