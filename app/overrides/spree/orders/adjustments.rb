Deface::Override.new(
  virtual_path: 'spree/orders/_adjustments',
  name:         'added avalara tax adjustment to cart',
  insert_top:   '#cart_adjustments',
  partial: "spree/shared/avalara_cart_adjustment"
)
