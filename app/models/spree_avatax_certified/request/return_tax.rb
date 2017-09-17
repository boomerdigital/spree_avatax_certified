class SpreeAvataxCertified::Request::ReturnTax < SpreeAvataxCertified::Request::Base

  def initialize(order, opts={})
    super
    @refund = opts[:refund]
  end

  def generate
    @request = {
      DocCode: order.number.to_s + '.' + @refund.id.to_s,
      DocDate: Date.today.strftime('%F'),
      Commit: @commit,
      DocType: @doc_type ? @doc_type : 'ReturnOrder',
      Addresses: address_lines,
      Lines: sales_lines
    }.merge(base_tax_hash)

    check_vat_id

    @request
  end

  protected

  def doc_date
    Date.today.strftime('%F')
  end

  def base_tax_hash
    super.merge(tax_override)
  end

  def tax_override
    {
      TaxOverride: {
        TaxOverrideType: 'TaxDate',
        Reason: @refund.try(:reason).try(:name).limit(255) || 'Return',
        TaxDate: order.completed_at.strftime('%F')
      }
    }
  end

  def sales_lines
    @sales_lines ||= SpreeAvataxCertified::Line.new(order, @doc_type, @refund).lines
  end
end
