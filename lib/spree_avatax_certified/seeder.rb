module SpreeAvataxCertified
  class Seeder
    class << self

      def seed!
        create_use_codes
        create_tax
        puts '***** SPREE AVATAX CERTIFIED *****'
        puts ''
        puts 'Please remember to:'
        puts '- Add tax category to all shipping methods that need to be taxed.'
        puts '- Dont assign anything default tax.'
        puts ''
        puts '***** SPREE AVATAX CERTIFIED *****'
      end

      def create_tax
        clothing = Spree::TaxCategory.find_or_create_by(name: 'Clothing')
        clothing.update_attributes(tax_code: 'P0000000')
        tax_zone = Spree::Zone.find_or_create_by(name: 'North America')
        tax_calculator = Spree::Calculator::AvalaraTransactionCalculator.create!
        sales_tax = Spree::TaxRate.find_or_create_by(name: 'Tax') do |tax_rate|
          # default values for the create
          tax_rate.amount = BigDecimal.new('0')
          tax_rate.calculator = tax_calculator
          tax_rate.tax_category = clothing
        end
        sales_tax.update!(tax_category: clothing, name: 'Tax', amount: BigDecimal.new('0'), zone: tax_zone, show_rate_in_label: false, calculator: tax_calculator)

        shipping = Spree::TaxCategory.find_or_create_by(name: 'Shipping', tax_code: 'FR000000')
        shipping_tax = Spree::TaxRate.find_or_create_by(name: 'Shipping Tax') do |shipping_tax|
          shipping_tax.tax_category = shipping
          shipping_tax.amount = BigDecimal.new('0')
          shipping_tax.zone = tax_zone
          shipping_tax.show_rate_in_label = false
        end
        shipping_tax.update!(tax_category: shipping, amount: BigDecimal.new('0'), zone: Spree::Zone.find_by_name('North America'), show_rate_in_label: false, calculator: Spree::Calculator::AvalaraTransactionCalculator.create!)
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
          'A' => 'Federal government',
          'B' => 'State government',
          'C' => 'Tribe/Status Indian/Indian Band',
          'D' => 'Foreign diplomat',
          'E' => 'Charitable or benevolent organization',
          'F' => 'Religious or educational organization',
          'G' => 'Resale',
          'H' => 'Commercial agricultural production',
          'I' => 'Industrial production/manufacturer',
          'J' => 'Direct pay permit',
          'K' => 'Direct mail',
          'L' => 'Other',
          'N' => 'Local government',
          'P' => 'Commercial aquaculture (Canada only)',
          'Q' => 'Commercial fishery (Canada only)',
          'R' => 'Non-resident (Canada only)'
        }
      end
    end
  end
end
