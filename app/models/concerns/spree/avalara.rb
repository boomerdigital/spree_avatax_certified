module Spree
  module Avalara
    extend ActiveSupport::Concern

    included do
      has_one :avalara_transaction, dependent: :destroy
    end

    def avalara_eligible
      Spree::Config.avatax_iseligible
    end
  end
end
