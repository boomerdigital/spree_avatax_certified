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

res = ask 'Would you like to seed use codes? [Y/n]'
if res == '' || res.downcase == 'y'

  unless Spree::AvalaraUseCodeItem.count >= 16
    use_codes.each do |key, value|
      Spree::AvalaraUseCodeItem.create(use_code: key, use_code_description: value)
    end
  end
  puts "Use codes seeded."
else
  puts 'Skipping use code seeds!'
end