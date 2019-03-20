require 'spec_helper'

RSpec.describe Spree::AvalaraTransaction, :vcr do

  let(:included_in_price) { false }
  let(:order) { create(:avalara_order, tax_included: included_in_price) }

  context 'captured orders' do

    describe '#lookup_avatax' do
      subject do
        order.avalara_transaction.lookup_avatax
      end

      it 'should look up avatax' do
        expect(subject['TotalTax']).to eq('0.6')
      end
    end

    describe '#commit_avatax' do
      subject do
        order.avalara_transaction.commit_avatax('SalesOrder')
      end

      it 'should commit avatax' do
        expect(subject['TotalTax']).to eq('0.6')
      end

      context 'tax calculation disabled' do
        let(:order) { create(:order_with_line_items, avalara_transaction: Spree::AvalaraTransaction.new) }

        it 'should respond with total tax of 0' do
          Spree::Config.avatax_tax_calculation = false
          expect(order.avalara_transaction.commit_avatax('SalesOrder')[:TotalTax]).to eq('0.00')
        end
      end

      context 'promo' do
        let(:promotion) { create(:promotion, :with_order_adjustment) }

        subject do
          create(:adjustment, order: order, source: promotion.promotion_actions.first, adjustable: order)
          order.update_with_updater!
          order.avalara_transaction.commit_avatax('SalesOrder')
        end

        it 'applies discount' do
          expect(subject['TotalDiscount']).to eq('10')
        end
      end

      context 'included_in_price' do
        let(:included_in_price) { true }

        subject do
          order.avalara_transaction.commit_avatax('SalesOrder')
        end

        it 'calculates the included tax amount from item total' do
          expect(subject['TotalTax']).to eq('0.57')
        end
      end

       context 'multiple stock locations', :vcr do
        let!(:stock_loc_1) { create(:stock_location) }
        let!(:stock_loc_2) { create(:stock_location) }
        let!(:var1) {
          variant = create(:variant)
          variant.stock_items.destroy_all
          variant.stock_items.create(stock_location_id: stock_loc_1.id, backorderable: true)
          variant
        }
        let!(:var2) {
          variant = create(:variant)
          variant.stock_items.destroy_all
          variant.stock_items.create(stock_location_id: stock_loc_2.id, backorderable: true)
          variant
        }
        let(:line_item1) { create(:line_item, variant: var1) }
        let(:line_item2) { create(:line_item, variant: var2) }
        let(:order) { create(:order_with_line_items, line_items: [line_item1, line_item2]) }

        before do
          order.create_proposed_shipments
          order.reload
          order.shipments.reload
        end

        it 'should have correct addresses' do
          tax_addresses = order.avalara_capture['TaxAddresses'].map { |a| a['Address'] }
          addresses = order.shipments.map { |s| s.stock_location.address1 }
          addresses << JSON.parse(Spree::Config.avatax_origin)['Address1']

          expect(tax_addresses).to include(*addresses)
        end
      end
    end

    describe '#commit_avatax_final' do
      subject do
        order.avalara_transaction.commit_avatax_final('SalesInvoice')
      end

      it 'should commit avatax final' do
        expect(subject['TotalTax']).to eq('0.6')
      end

      it 'should fail to commit to avatax if settings are false' do
        Spree::Config.avatax_document_commit = false

        expect(subject).to eq('Avalara Document Committing Disabled')
      end

      context 'tax calculation disabled' do
        let(:order) { create(:order_with_line_items, avalara_transaction: Spree::AvalaraTransaction.new) }

        it 'should respond with total tax of 0' do
          Spree::Config.avatax_tax_calculation = false
          expect(order.avalara_transaction.commit_avatax_final('SalesInvoice')[:TotalTax]).to eq('0.00')
        end
      end

      context 'with CustomerUsageType' do
        let(:use_code) { create(:avalara_entity_use_code) }

        subject do
          order.user.update_attributes(avalara_entity_use_code: use_code)
          order.avalara_transaction.commit_avatax('SalesInvoice')
        end

        it 'does not add additional tax' do
          expect(subject['TotalTax']).to eq('0')
        end
      end
    end

    describe '#cancel_order' do
      let(:order) { create(:completed_avalara_order) }
      subject do
        order.avalara_capture_finalize
        order.avalara_transaction.cancel_order
      end

      it 'should receive ResultCode of Success' do
        expect(subject['ResultCode']).to eq('Success')
      end

      context 'error' do
        it 'should receive error' do
          order = create(:order)
          order.avalara_transaction = Spree::AvalaraTransaction.create
          expect(order.avalara_transaction).to receive(:cancel_order_to_avalara).and_return('Error in Tax')
          order.avalara_transaction.cancel_order
        end
      end
    end
  end

  context 'return orders' do
    let(:order) { create(:completed_avalara_order) }
    let(:reimbursement) { create(:reimbursement, order: order) }
    let(:refund) { build(:refund, payment: order.payments.first, amount: order.total.to_f) }

    before do
      order.avalara_capture_finalize
      order.reload
    end

    describe '#commit_avatax' do
      subject do
        order.avalara_transaction.commit_avatax('ReturnOrder', refund)
      end

      it 'should receive a ResultCode of Success' do
        expect(subject['ResultCode']).to eq('Success')
      end

      it 'should have a TotalTax equal to additional_tax_total' do
        expect(subject['TotalTax']).to eq("#{-order.additional_tax_total.to_f}")
      end
    end

    describe '#commit_avatax_final' do
      subject do
        order.avalara_transaction.commit_avatax_final('ReturnOrder', refund)
      end


      it 'should commit avatax final' do
        expect(subject).to be_kind_of(Hash)
        expect(subject['ResultCode']).to eq('Success')
        expect(subject['TotalTax']).to eq("#{-order.additional_tax_total.to_f}")
      end

      it 'should receive post_order_to_avalara' do
        expect(order.avalara_transaction).to receive(:post_return_to_avalara)
        subject
      end
    end
  end
end
