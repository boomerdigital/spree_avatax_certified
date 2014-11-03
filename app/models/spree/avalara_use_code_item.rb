module Spree
  class AvalaraUseCodeItem < ActiveRecord::Base
    belongs_to :spree_user_decorator
  end
end
