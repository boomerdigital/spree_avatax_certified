Spree.user_class = "Spree::User"
Spree::PermittedAttributes.user_attributes.concat([:avalara_entity_use_code_id, :exemption_number, :vat_id])
Rails.application.config.spree.calculators.tax_rates << Spree::Calculator::AvalaraTransactionCalculator
