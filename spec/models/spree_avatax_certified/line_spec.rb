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
  let!(:return_authorization) { Spree::ReturnAuthorization.create(:order => shipped_order, :stock_location => stock_location) }

  before do
    order.ship_address.update_attributes(city: 'Tuscaloosa', address1: '220 Paul W Bryant Dr')
    order.shipments.first.selected_shipping_rate.update_attributes(tax_rate: rate)
  end

  let(:sales_lines) { SpreeAvataxCertified::Line.new(order, 'SalesOrder') }
  let(:return_lines) { SpreeAvataxCertified::Line.new(shipped_order, 'ReturnOrder') }

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
    it 'lines should be a length of 6' do
      expect(sales_lines.lines.length).to eq(6)
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
    describe 'build_lines' do
      it 'receives method return_authorization_lines' do
        expect(return_lines).to receive(:return_authorization_lines)
        return_lines.build_lines
      end
    end
    describe '#return_authorization_lines' do
      it 'returns an array' do
        expect(return_lines.return_authorization_lines).to be_kind_of(Array)
      end
    end
  end
end
