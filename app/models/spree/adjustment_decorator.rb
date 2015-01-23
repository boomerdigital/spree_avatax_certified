Spree::Adjustment.class_eval do
  scope :avalara_tax, -> { where(source_type: 'Spree::AvalaraTransaction') }
  scope :not_avalara_tax, -> { where.not(source_type: 'Spree::AvalaraTransaction') }
end