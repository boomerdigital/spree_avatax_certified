Spree::Adjustment.class_eval do
  scope :avalara_tax, -> { where(source_type: 'Spree::AvalaraTransaction') }
  scope :reimbursement, -> { where(source_type: "Spree::Reimbursement") }
end