module Spree
  class AvalaraUseCodeItem < ActiveRecord::Base
    belongs_to :user, class_name: 'Spree::User'
  end
end
