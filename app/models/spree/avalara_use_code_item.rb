module Spree
  class AvalaraUseCodeItem < ActiveRecord::Base
    has_many :users, class_name: Spree.user_class.to_s, foreign_key: :avalara_use_code_item_id
  end
end
