module SpreeAvataxCertified
  class Seeder
    class << self

      def seed!
        create_use_codes
        create_tax
        puts "***** SPREE AVATAX CERTIFIED *****"
        puts ""
        puts "Please remember to:"
        puts "- Add tax category to all shipping methods that need to be taxed."
        puts "- Don't assign anything default tax."
        puts ""
        puts "***** SPREE AVATAX CERTIFIED *****"
      end

      def create_tax
        clothing = Spree::TaxCategory.find_or_create_by(name: 'Clothing')
        clothing.update_attributes(tax_code: 'P0000000')

        shipping = Spree::TaxCategory.find_or_create_by(name: 'Shipping', tax_code: 'FR000000')

        sales_tax = Spree::TaxRate.find_or_create_by(name: 'North America')
        sales_tax.update_attributes(tax_category: clothing, name: 'Tax', amount: BigDecimal.new('0'), zone: Spree::Zone.find_by_name('North America'), show_rate_in_label: false)
        sales_tax.calculator = Spree::Calculator::AvalaraTransactionCalculator.create!
        sales_tax.save!

        shipping_tax = Spree::TaxRate.create(name: 'Shipping Tax', tax_category: shipping, amount: BigDecimal.new('0'), zone: Spree::Zone.find_by_name('North America'), show_rate_in_label: false)
        shipping_tax.calculator = Spree::Calculator::AvalaraTransactionCalculator.create!
        shipping_tax.save!
      end

      def create_use_codes
        unless Spree::AvalaraEntityUseCode.count >= 16
          use_codes.each do |key, value|
            Spree::AvalaraEntityUseCode.find_or_create_by(use_code: key, use_code_description: value)
          end
        end
      end

      def use_codes
        {
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
      end
    end
  end
end
