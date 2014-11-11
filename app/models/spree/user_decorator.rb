Spree.user_class.class_eval do
  belongs_to :spree_avalara_use_code_item#, dependent: :destroy
end
