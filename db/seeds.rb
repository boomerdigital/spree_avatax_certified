use_codes = {
  "A" => "Federal government",
  "B" => "State government",
  "C" => "Tribe/Status Indian/Indian Band",
  "D" => "Foreign diplomat",
  "E" => "Charitable or benevolent organization",
  "F" => "Religious or educational organization",
  "G" => "Resale",
  "H" => "Commercial agricultural production",
  "I" => "Industrial production/manufacturer",
  "J" => "Direct pay permit",
  "K" => "Direct mail",
  "L" => "Other",
  "N" => "Local government",
  "P" => "Commercial aquaculture (Canada only)",
  "Q" => "Commercial fishery (Canada only)",
  "R" => "Non-resident (Canada only)"
}

clothing = Spree::TaxCategory.find_by_name('Clothing')
shipping = Spree::TaxCategory.create!(name: 'Shipping', tax_code: 'FR000000')

shipping_tax = Spree::TaxRate.create(name: 'Shipping Tax', tax_category: shipping, amount: BigDecimal.new('0'), zone: Spree::Zone.find_by_name('North America'))
shipping_tax.calculator = Spree::Calculator::AvalaraTransactionCalculator.create!
shipping_tax.save!



res = ask 'Would you like to seed use codes? [Y/n]'
if res == '' || res.downcase == 'y'

  unless Spree::AvalaraEntityUseCode.count >= 16
    use_codes.each do |key, value|
      Spree::AvalaraEntityUseCode.create(use_code: key, use_code_description: value)
    end
  end
  puts "Use codes seeded."
else
  puts 'Skipping use code seeds!'
end

puts "Please remember to:"
puts "- Create Tax Rates for each tax category and assign them the AvalaraTransactionCalculator"
puts "- Add tax category to all shipping methods that need to be taxed."
puts "- Don't assign anything default tax."
