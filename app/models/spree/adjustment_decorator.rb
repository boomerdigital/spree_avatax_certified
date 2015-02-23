Spree::Adjustment.class_eval do
  scope :all_tax, -> { where("source_type = 'Spree::TaxRate' OR source_type = 'Spree::AvalaraTransaction'") }
  scope :avalara_tax, -> { where(source_type: 'Spree::AvalaraTransaction') }
  scope :not_avalara_tax, -> { where.not(source_type: 'Spree::AvalaraTransaction') }
end