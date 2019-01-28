FactoryBot.define do
  factory :response_hash_success, class: Hash do
    ResultCode { 'Success' }
    DocCode { 'R207073277' }
    DocDate { '2017-03-22' }
    Timestamp { '2017-03-22T19:58:32.6529101Z' }
    TotalAmount { '15' }
    TotalDiscount { '0' }
    TotalExemption { '0' }
    TotalTaxable { '15' }
    TotalTax { '0.6' }
    TotalTaxCalculated { '0.6' }
    TaxLines { [
      {'LineNo'=>'1-LI',
       'TaxCode'=>'PC030000',
       'Taxability'=>'true',
       'BoundaryLevel'=>'Zip5',
       'Exemption'=>'0',
       'Discount'=>'0',
       'Taxable'=>'10',
       'Rate'=>'0.040000',
       'Tax'=>'0.4',
       'TaxCalculated'=>'0.4',
       'TaxDetails'=>
       [{'Country'=>'US',
         'Region'=>'AL',
         'JurisType'=>'State',
         'JurisCode'=>'01',
         'Taxable'=>'10',
         'Rate'=>'0.040000',
         'Tax'=>'0.4',
         'JurisName'=>'ALABAMA',
         'TaxName'=>'AL STATE TAX'}]},
      {'LineNo'=>'1-FR',
       'TaxCode'=>'FR000000',
       'Taxability'=>'true',
       'BoundaryLevel'=>'Zip5',
       'Exemption'=>'0',
       'Discount'=>'0',
       'Taxable'=>'5',
       'Rate'=>'0.040000',
       'Tax'=>'0.2',
       'TaxCalculated'=>'0.2',
       'TaxDetails'=>
       [{'Country'=>'US',
         'Region'=>'AL',
         'JurisType'=>'State',
         'JurisCode'=>'01',
         'Taxable'=>'5',
         'Rate'=>'0.040000',
         'Tax'=>'0.2',
         'JurisName'=>'ALABAMA',
         'TaxName'=>'AL STATE TAX'}]}
    ] }
    TaxAddresses { [
      {'Address'=>'A Different Road',
       'AddressCode'=>'Dest',
       'City'=>'Montgomery',
       'Country'=>'US',
       'PostalCode'=>'36104',
       'Region'=>'AL',
       'TaxRegionId'=>'2052799',
       'JurisCode'=>'0110151000'},
      {'Address'=>'1600 Pennsylvania Ave NW',
       'AddressCode'=>'2',
       'City'=>'Washington',
       'Country'=>'US',
       'PostalCode'=>'20500',
       'Region'=>'DC',
       'TaxRegionId'=>'0',
       'JurisCode'=>'1100000000'}
    ] }
    TaxDate { '2017-03-22' }
  end

  factory :response_hash_error, class: Hash do
    ResultCode { 'Error' }
    Messages { [
      {
        'Summary'=>'Lines[0].TaxCode length must be between 0 and 25 characters.',
        'RefersTo'=>'Lines[0].TaxCode',
        'Severity'=>'Error',
        'Source'=>'Avalara.AvaTax.Services'
      }
    ] }
  end
end
