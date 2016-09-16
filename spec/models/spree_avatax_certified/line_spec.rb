require 'spec_helper'

describe SpreeAvataxCertified::Line, :type => :model do

  let(:order) { FactoryGirl.create(:avalara_order) }
  let(:shipped_order) { FactoryGirl.create(:shipped_order) }
  let(:stock_location) { FactoryGirl.create(:stock_location) }

  let(:sales_lines) { SpreeAvataxCertified::Line.new(order, 'SalesOrder') }

  describe '#initialize' do
    it 'should have order' do
      expect(sales_lines.order).to eq(order)
    end
    it 'should have lines be an array' do
      expect(sales_lines.lines).to be_kind_of(Array)
    end
    it 'lines should be a length of 2' do
      expect(sales_lines.lines.length).to eq(2)
    end
  end

  context 'product line content' do
    let(:product_line) { sales_lines.lines[0] }


    it 'line number' do
      expect(product_line[:LineNo]).to eq("#{order.line_items.first.id}-LI")
    end

    it 'amount' do
      expect(product_line[:Amount]).to eq(10.0)
    end

    it 'OriginCode' do
      origin = order.line_items.first.inventory_units.first.shipment.stock_location_id

      expect(product_line[:OriginCode]).to eq(origin.to_s)
    end

    it 'no CustomerUsageType' do
      expect(product_line[:CustomerUsageType]).to eq(order.customer_usage_type)
    end

    it 'with CustomerUsageType' do
      use_code = create(:avalara_entity_use_code)
      order.user.update_attributes(avalara_entity_use_code: use_code)
      sales_lines = SpreeAvataxCertified::Line.new(order, 'SalesOrder')

      expect(sales_lines.lines[0][:CustomerUsageType]).to eq(use_code.use_code)
    end

    it 'without TaxIncluded' do
      expect(product_line[:TaxIncluded]).to eq(false)
    end

    it 'with TaxIncluded' do
      order.tax_zone.tax_rates.update_all(included_in_price: true)
      sales_lines = SpreeAvataxCertified::Line.new(order, 'SalesOrder')

      expect(sales_lines.lines[0][:TaxIncluded]).to eq(true)
    end
  end


  context 'shipment line content' do
    let(:shipment_line) { sales_lines.lines.last }


    it 'line number' do
      expect(shipment_line[:LineNo]).to eq("#{order.shipments.first.id}-FR")
    end

    it 'amount' do
      expect(shipment_line[:Amount]).to eq(5.0)
    end

    it 'OriginCode' do
      origin = order.shipments.first.stock_location_id

      expect(shipment_line[:OriginCode]).to eq(origin.to_s)
    end

    it 'no CustomerUsageType' do
      expect(shipment_line[:CustomerUsageType]).to eq(order.customer_usage_type)
    end

    it 'with CustomerUsageType' do
      use_code = create(:avalara_entity_use_code)
      order.user.update_attributes(avalara_entity_use_code: use_code)
      sales_lines = SpreeAvataxCertified::Line.new(order, 'SalesOrder')

      expect(sales_lines.lines.last[:CustomerUsageType]).to eq(use_code.use_code)
    end

    it 'without TaxIncluded' do
      expect(shipment_line[:TaxIncluded]).to eq(false)
    end

    it 'with TaxIncluded' do
      order.tax_zone.tax_rates.update_all(included_in_price: true)
      sales_lines = SpreeAvataxCertified::Line.new(order, 'SalesOrder')

      expect(sales_lines.lines.last[:TaxIncluded]).to eq(true)
    end
  end

  context 'sales order' do
    describe '#build_lines' do
      it 'receives method item_lines_array' do
        expect(sales_lines).to receive(:item_lines_array)
        sales_lines.build_lines
      end
      it 'receives method shipment_lines_array' do
        expect(sales_lines).to receive(:shipment_lines_array)
        sales_lines.build_lines
      end
    end

    describe '#item_lines_array' do
      it 'returns an Array' do
        expect(sales_lines.item_lines_array).to be_kind_of(Array)
      end
    end

    describe '#shipment_lines_array' do
      it 'returns an Array' do
        expect(sales_lines.shipment_lines_array).to be_kind_of(Array)
      end
      it 'should have a length of 1' do
        expect(sales_lines.shipment_lines_array.length).to eq(1)
      end
    end

    describe '#item_line' do
      it 'returns a Hash' do
        expect(sales_lines.item_line(order.line_items.first)).to be_kind_of(Hash)
      end
    end
    describe '#shipment_line' do
      it 'returns a Hash' do
        expect(sales_lines.shipment_line(order.shipments.first)).to be_kind_of(Hash)
      end
    end
  end

  context 'return invoice' do
    let(:authorization) { generate(:refund_transaction_id) }
    let(:payment_amount) { 10*2 }
    let(:payment_method) { create(:credit_card_payment_method) }
    let(:payment) { create(:payment, amount: payment_amount, payment_method: payment_method, order: order) }
    let(:refund_reason) { create(:refund_reason) }
    let(:gateway_response) {
      ActiveMerchant::Billing::Response.new(
        gateway_response_success,
        gateway_response_message,
        gateway_response_params,
        gateway_response_options
      )
    }
    let(:gateway_response_success) { true }
    let(:gateway_response_message) { "" }
    let(:gateway_response_params) { {} }
    let(:gateway_response_options) { {} }

    let(:refund) {Spree::Refund.new(payment: payment, amount: BigDecimal.new(10), reason: refund_reason, transaction_id: nil)}
    let(:shipped_order) { FactoryGirl.create(:shipped_order) }
    let(:return_lines) { SpreeAvataxCertified::Line.new(shipped_order, 'ReturnOrder', refund) }

    describe 'build_lines' do
      it 'receives method refund_lines' do
        expect(return_lines).to receive(:refund_lines)
        return_lines.build_lines
      end
    end
    describe '#refund_line' do
      it 'returns an Hash' do
        expect(return_lines.refund_line).to be_kind_of(Hash)
      end
    end
    describe '#refund_line' do
      it 'returns an Array' do
        expect(return_lines.refund_lines).to be_kind_of(Array)
      end
    end

    context 'refund line content' do
      let(:refund_line) { return_lines.lines[0] }

      it 'amount' do
        expect(refund_line[:Amount]).to eq(-10.0)
      end

      it 'no CustomerUsageType' do
        expect(refund_line[:CustomerUsageType]).to eq(order.customer_usage_type)
      end

      it 'with CustomerUsageType' do
        use_code = create(:avalara_entity_use_code)
        order.user.update_attributes(avalara_entity_use_code: use_code)
        refund_lines = SpreeAvataxCertified::Line.new(order, 'SalesOrder')

        expect(refund_lines.lines.last[:CustomerUsageType]).to eq(use_code.use_code)
      end

      it 'with TaxIncluded' do
        expect(refund_line[:TaxIncluded]).to eq(true)
      end
    end
  end
end
