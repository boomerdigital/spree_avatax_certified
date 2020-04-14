FactoryBot.define do
  factory :response_hash_success, class: Hash do
    id { 0 }
    code { "R432426823" }
    companyId { 0 }
    date { "2017-05-31" }
    paymentDate { "2017-05-31" }
    status { "Temporary" }
    type { "SalesOrder" }
    currencyCode { "USD" }
    customerVendorCode { "1" }
    reconciled { false }
    referenceCode { "R432426823" }
    totalAmount { 10.0 }
    totalExempt { 0.0 }
    totalTax { 0.4 }
    totalTaxable { 10.0 }
    totalTaxCalculated { 0.4 }
    adjustmentReason { "NotAdjusted" }
    locked { false }
    version { 1 }
    exchangeRateEffectiveDate { "2017-05-31" }
    exchangeRate { 1.0 }
    isSellerImporterOfRecord { false }
    modifiedDate { "2017-05-31T22:04:02.1273454Z" }
    modifiedUserId { 37_777 }
    taxDate { "0001-01-01T00:00:00" }
    lines {
      [{
        "id" => 0,
        "transactionId" => 0,
        "lineNumber" => "1-LI",
        "description" => "",
        "discountAmount" => 0.0,
        "exemptAmount" => 0.0,
        "exemptCertId" => 0,
        "isItemTaxable" => true,
        "itemCode" => "",
        "lineAmount" => 10.0,
        "quantity" => 0.0,
        "reportingDate" => "2017-05-31",
        "tax" => 0.4,
        "taxableAmount" => 10.0,
        "taxCalculated" => 0.4,
        "taxCode" => "PC030000",
        "taxDate" => "2017-05-31",
        "taxIncluded" => false,
        "details" => [{
          "id" => 0,
          "transactionLineId" => 0,
          "transactionId" => 0,
          "country" => "US",
          "region" => "AL",
          "exemptAmount" => 0.0,
          "jurisCode" => "01",
          "jurisName" => "ALABAMA",
          "stateAssignedNo" => "",
          "jurisType" => "STA",
          "nonTaxableAmount" => 0.0,
          "rate" => 0.04,
          "tax" => 0.4,
          "taxableAmount" => 10.0,
          "taxType" => "Sales",
          "taxName" => "AL STATE TAX",
          "taxAuthorityTypeId" => 45,
          "taxCalculated" => 0.4,
          "rateType" => "General",
          "rateTypeCode" => "G"
        }]
      }]
    }
    addresses {
      [{
        "id" => 0,
        "transactionId" => 0,
        "boundaryLevel" => "Address",
        "line1" => "915 S Jackson St",
        "city" => "Montgomery",
        "region" => "AL",
        "postalCode" => "36104",
        "country" => "US",
        "taxRegionId" => 2_052_799,
        "latitude" => "32.365963",
        "longitude" => "-86.296036"
      }, {
        "id" => 0,
        "transactionId" => 0,
        "boundaryLevel" => "Address",
        "line1" => "1600 Pennsylvania Ave NW",
        "city" => "Washington",
        "region" => "DC",
        "postalCode" => "20500",
        "country" => "US",
        "taxRegionId" => 949,
        "latitude" => "38.898636",
        "longitude" => "-77.036543"
      }]
    }
    summary {
      [{
        "country" => "US",
        "region" => "AL",
        "jurisType" => "State",
        "jurisCode" => "01",
        "jurisName" => "ALABAMA",
        "taxAuthorityType" => 45,
        "stateAssignedNo" => "",
        "taxType" => "Sales",
        "taxName" => "AL STATE TAX",
        "taxGroup" => "",
        "rateType" => "General",
        "rateTypeCode" => "G",
        "taxable" => 10.0,
        "rate" => 0.04,
        "tax" => 0.4,
        "taxCalculated" => 0.4,
        "nonTaxable" => 0.0,
        "exemption" => 0.0
      }]
    }

    initialize_with { attributes.stringify_keys }
  end

  factory :response_hash_error, class: Hash do
    error {
      {
        "code" => "EntityNotFoundError",
        "message" => "Document with ID '54321:R542706814' not found.",
        "target" => "HttpRequest",
        "details" => [{
          "code" => "EntityNotFoundError",
          "number" => 4,
          "message" => "Document with ID '54321:R542706814' not found.",
          "faultCode" => "Client",
          "helpLink" => "http://developer.avalara.com/avatax/errors/EntityNotFoundError",
          "severity" => "Error"
        }]
      }
    }

    initialize_with { attributes.stringify_keys }
  end
end
