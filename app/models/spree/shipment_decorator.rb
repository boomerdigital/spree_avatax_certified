Spree::Shipment.class_eval do
      def update_amounts
      if selected_shipping_rate
        self.update_columns(
          cost: selected_shipping_rate.cost,
          # adjustment_total: adjustments.additional.map(&:update!).compact.sum,
          updated_at: Time.now,
        )
      end
    end
end