module Spree
  Spree.user_class.class_eval do
    has_one :spree_avalara_use_code
  end
end
