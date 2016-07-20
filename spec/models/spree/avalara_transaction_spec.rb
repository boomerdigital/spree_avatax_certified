require 'spec_helper'

describe Spree::AvalaraTransaction, :type => :model do

  it { should belong_to :order }
  it { should validate_presence_of :order }
  it { should validate_uniqueness_of :order_id }
  it { should have_db_index :order_id }
  it { should have_many :adjustments }

  let(:order) {
    order = create(:order_with_line_items)
    order.reload
  }
  let!(:rate) { create(:avalara_tax_rate, tax_category: order.line_items.first.tax_category) }

  context 'captured orders' do

    before :each do
      order.avalara_capture
    end

    describe "#lookup_avatax" do
      it "should look up avatax" do
        expect(order.avalara_transaction.lookup_avatax["TotalTax"]).to eq("2")
      end
    end

    describe "#commit_avatax" do
      it "should commit avatax" do
        expect(order.avalara_transaction.commit_avatax('SalesOrder')["TotalTax"]).to eq("2")
      end

      it 'should receive post_order_to_avalara' do
        expect(order.avalara_transaction).to receive(:post_order_to_avalara)
        order.avalara_transaction.commit_avatax('SalesOrder')
      end

      context 'tax calculation disabled' do
        it 'should respond with total tax of 0' do
          Spree::Config.avatax_tax_calculation = false
          expect(order.avalara_transaction.commit_avatax('SalesOrder')[:TotalTax]).to eq("0.00")
        end
      end

      context 'promo' do
        let(:promotion) { create(:promotion, :with_order_adjustment) }

        before do
          create(:adjustment, order: order, source: promotion.promotion_actions.first, adjustable: order)
          order.update!
        end
        it 'applies discount' do
          expect(order.avalara_transaction.commit_avatax('SalesInvoice')['TotalDiscount']).to eq('10')
        end
      end

      context 'included_in_price' do
        before do
          rate.update_attributes(included_in_price: true)
          order.reload
        end

        it 'calculates the included tax amount from item total' do
          expect(order.avalara_transaction.commit_avatax('SalesOrder')["TotalTax"]).to eq("1.9")
        end
      end
    end

    describe "#commit_avatax_final" do
      it "should commit avatax final" do
        expect(order.avalara_transaction.commit_avatax_final('SalesInvoice')["TotalTax"]).to eq("2")
      end

      it 'should receive post_order_to_avalara' do
        expect(order.avalara_transaction).to receive(:post_order_to_avalara)
        order.avalara_transaction.commit_avatax_final('SalesInvoice')
      end

      it "should fail to commit to avatax if settings are false" do
        Spree::Config.avatax_document_commit = false

        expect(order.avalara_transaction.commit_avatax_final('SalesInvoice')).to eq("avalara document committing disabled")
      end

      context 'tax calculation disabled' do
        it 'should respond with total tax of 0' do
          Spree::Config.avatax_tax_calculation = false
          expect(order.avalara_transaction.commit_avatax_final('SalesInvoice')[:TotalTax]).to eq("0.00")
        end
      end
    end

    describe '#cancel_order' do
      it 'should receive cancel_order_to_avalara' do
        expect(order.avalara_transaction).to receive(:cancel_order_to_avalara)
        order.avalara_transaction.cancel_order
      end

      it 'should receive error' do
        order = create(:order)
        order.avalara_transaction = Spree::AvalaraTransaction.create
        expect(order.avalara_transaction).to receive(:cancel_order_to_avalara).and_return('Error in Tax')
        order.avalara_transaction.cancel_order
      end
    end

    describe '#adjust_avatax' do
      let(:adjusted_order) {
        order.avalara_capture_finalize
        order.reload
      }
      subject { adjusted_order.avalara_transaction.adjust_avatax }

      it 'should receive adjust_order_to_avalara' do
        expect(adjusted_order.avalara_transaction).to receive(:adjust_order_to_avalara)
        subject
      end

      it "should be successful" do
        expect(subject[:total_tax]).to eq("2")
      end
    end
  end

  context 'return orders' do
    let(:order) { create(:shipped_order) }
    let(:inventory_unit) { order.shipments.first.inventory_units.first }
    let(:return_auth) { create(:return_authorization, order: order, inventory_units: [inventory_unit]) }

    before do
      test = order.avalara_capture_finalize
      order.reload
    end

    describe '#commit_avatax' do
      it 'should receive post_return_to_avalara' do
        expect(order.avalara_transaction).to receive(:post_return_to_avalara)
        order.avalara_transaction.commit_avatax('ReturnOrder', return_auth)
      end
    end

    describe '#commit_avatax_final' do
      it 'should commit avatax final' do
        response = order.avalara_transaction.commit_avatax_final('ReturnOrder', return_auth)
        expect(response).to be_kind_of(Hash)
        expect(response['ResultCode']).to eq('Success')
      end
      it 'should receive post_return_to_avalara' do
        expect(order.avalara_transaction).to receive(:post_return_to_avalara)
        order.avalara_transaction.commit_avatax_final('ReturnOrder', return_auth)
      end
    end
  end
end
