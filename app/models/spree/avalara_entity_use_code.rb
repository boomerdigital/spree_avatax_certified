module Spree
  class AvalaraEntityUseCode < Spree::Base
    has_many :users, class_name: Spree.user_class.to_s, foreign_key: :avalara_entity_use_code_id
  end
end
