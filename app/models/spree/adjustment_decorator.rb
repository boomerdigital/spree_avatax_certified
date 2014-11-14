Spree::Adjustment.class_eval do
  scope :avalara_tax, -> { where(source_type: 'Spree::AvalaraTransaction') }
end