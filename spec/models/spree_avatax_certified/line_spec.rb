require 'spec_helper'

describe SpreeAvataxCertified::Line, :type => :model do
  let(:country){ FactoryGirl.create(:country) }
  let!(:zone) { create(:zone, :name => "North America", :default_tax => true, :zone_members => []) }
  let(:zone_member) { Spree::ZoneMember.create() }
  let!(:tax_category) { Spree::TaxCategory.create(name: 'Shipping', description: 'FR000000') }
  let(:included_in_price) { false }
  let!(:rate) { create(:tax_rate, :tax_category => tax_category, :amount => 0.00, :included_in_price => included_in_price, zone: zone) }
  let!(:calculator) { Spree::Calculator::AvalaraTransactionCalculator.new(:calculable => rate ) }
  let(:address){ FactoryGirl.create(:address) }
  let(:order) { FactoryGirl.create(:order_with_line_items) }
  let(:shipped_order) { FactoryGirl.create(:shipped_order) }
  let(:stock_location) { FactoryGirl.create(:stock_location) }

  before do
    order.ship_address.update_attributes(city: 'Tuscaloosa', address1: '220 Paul W Bryant Dr')
    order.shipments.first.selected_shipping_rate.update_attributes(tax_rate: rate)
  end

  let(:sales_lines) { SpreeAvataxCertified::Line.new(order, 'SalesOrder') }

  describe '#initialize' do
    it 'should have order' do
      expect(sales_lines.order).to eq(order)
    end
    it 'should have invoice_type' do
      expect(sales_lines.invoice_type).to eq('SalesOrder')
    end
    it 'should have lines be an array' do
      expect(sales_lines.lines).to be_kind_of(Array)
    end
    it 'lines should be a length of 2' do
      expect(sales_lines.lines.length).to eq(2)
    end
    it 'should have stock locations' do
      expect(sales_lines.stock_locations).to eq(sales_lines.order_stock_locations)
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

    let(:reimbursement) { create(:reimbursement) }

    let(:refund) {Spree::Refund.new(payment: payment, amount: BigDecimal.new(10), reason: refund_reason, transaction_id: nil, reimbursement: reimbursement)}
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
  end
end
