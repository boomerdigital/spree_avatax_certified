Spree::Adjustment.class_eval do
  scope :avalara_tax, -> { where(originator_type: 'Spree::AvalaraTransaction') }
end
