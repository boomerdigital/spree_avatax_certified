require 'spec_helper'

describe Spree::AvalaraTransaction, :type => :model do

  it { should belong_to :order }
  it { should validate_presence_of :order }
  it { should validate_uniqueness_of :order_id }
  it { should have_db_index :order_id }
  it { should have_many :adjustments }

  let(:country) { create(:country) }
  let(:state) { create(:state) }
  let(:order) { create(:order_with_line_items) }

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
        expect(order.avalara_transaction.commit_avatax('SalesInvoice')["TotalTax"]).to eq("2")
      end

      it 'should receive post_order_to_avalara' do
        expect(order.avalara_transaction).to receive(:post_order_to_avalara)
        order.avalara_transaction.commit_avatax('SalesInvoice')
      end

      context 'tax calculation disabled' do
        it 'should respond with total tax of 0' do
          Spree::Config.avatax_tax_calculation = false
          expect(order.avalara_transaction.commit_avatax('SalesInvoice')[:TotalTax]).to eq("0.00")
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
end
