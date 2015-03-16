Spree::Promotion.class_eval do

  def activate(payload)
      order = payload[:order]
      return unless self.class.order_activatable?(order)

      payload[:promotion] = self

      # Track results from actions to see if any action has been taken.
      # Actions should return nil/false if no action has been taken.
      # If an action returns true, then an action has been taken.
      results = actions.map do |action|
        action.perform(payload)
      end
      # If an action has been taken, report back to whatever activated this promotion.
      action_taken = results.include?(true)

      if action_taken
      # connect to the order
      # create the join_table entry.
        self.orders << order
        self.save
        if order.avalara_eligible
          order.avalara_capture
        end
      end

      return action_taken
    end

end