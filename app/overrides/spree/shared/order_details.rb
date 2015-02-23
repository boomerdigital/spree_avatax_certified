Deface::Override.new(
  virtual_path: 'spree/shared/_order_details',
  name:         'added avalara tax adjustment',
  insert_bottom:   '[data-hook="order_details_subtotal"]',
  partial: "spree/shared/avalara_confirmation_adjustment"
)
