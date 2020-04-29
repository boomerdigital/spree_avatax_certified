class SpreeAvataxCertified::Request::GetTax < SpreeAvataxCertified::Request::Base
  def generate
    promotion_discount = order.all_adjustments.promotion.eligible.sum(:amount).abs
    manual_discount = order.all_adjustments.where('amount < 0').where(source: nil).eligible.sum(:amount).abs

    {
      createTransactionModel: {
        code: order.number,
        date: doc_date,
        discount: (promotion_discount + manual_discount).to_s,
        commit: @commit,
        type: @doc_type || 'SalesOrder',
        lines: sales_lines,
        addresses: address_lines
      }.merge(base_tax_hash)
    }
  end

  protected

  def doc_date
    order.completed? ? order.completed_at.strftime('%F') : Date.today.strftime('%F')
  end
end
