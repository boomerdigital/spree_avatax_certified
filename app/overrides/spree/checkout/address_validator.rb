Deface::Override.new(
  virtual_path: 'spree/checkout/_address',
  name: 'add validator button',
  insert_bottom: '[data-hook="billing_fieldset_wrapper"]',
  partial: 'spree/shared/address_validator_button'
)
