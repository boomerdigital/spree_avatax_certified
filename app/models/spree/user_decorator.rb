module Spree::UserDecorator
  def self.prepended(base)
    base.belongs_to :avalara_entity_use_code
  end

  Spree.user_class.prepend self
end
