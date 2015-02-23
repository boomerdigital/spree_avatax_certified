Deface::Override.new(
  virtual_path: 'spree/checkout/_summary',
  name:         'fix tax adjustment view',
  replace:   '[data-hook="order_details_tax_adjustments"]',
  partial: "spree/shared/order_details_tax_adjustments"
)
