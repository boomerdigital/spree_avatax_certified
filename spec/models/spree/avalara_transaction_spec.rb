require 'spec_helper'

describe Spree::AvalaraTransaction, :type => :model do

  it { should belong_to :order }
  it { should belong_to :reimbursement }
  it { should belong_to :refund }
  it { should validate_presence_of :order }
  it { should validate_uniqueness_of :order_id }
  it { should have_db_index :order_id }
  it { should have_many :adjustments }

  let(:country) { create(:country) }
  let(:state) { create(:state) }
  let(:order) { create(:order_with_line_items) }

  before :each do
    MyConfigPreferences.set_preferences
    stock_location = FactoryGirl.create(:stock_location)
    order.line_items.first.tax_category.update_attributes(name: "Clothing", description: "PC030000")
  end

  context 'captured orders' do

    before :each do
      order.avalara_capture
    end

    describe "#lookup_avatax" do
      it "should look up avatax" do
        expect(order.avalara_transaction.lookup_avatax["TotalTax"]).to eq("0.4")
      end
    end

    describe "#commit_avatax" do
      it "should commit avatax" do
        expect(order.avalara_transaction.commit_avatax('SalesInvoice')["TotalTax"]).to eq("0.4")
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

      context 'promo' do
        it 'applies discount' do
          order.promo_total = 10
          expect(order.avalara_transaction.commit_avatax('SalesInvoice')['TotalDiscount']).to eq('10')
        end
      end
    end

    describe "#commit_avatax_final" do
      it "should commit avatax final" do
        expect(order.avalara_transaction.commit_avatax_final('SalesInvoice')["TotalTax"]).to eq("0.4")
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
  end

  context 'return orders' do
    let(:refund_reason) { create(:refund_reason) }
    let(:reimbursement) { create(:reimbursement) }
    let(:order) { reimbursement.order }
    let!(:refund) {Spree::Refund.create(payment: order.payments.first, amount: BigDecimal.new(10), reason: refund_reason, transaction_id: nil, reimbursement: reimbursement)}

    before do
      order.avalara_capture_finalize
      order.reload
    end

    describe '#commit_avatax' do
      it 'should receive post_return_to_avalara' do
        expect(order.avalara_transaction).to receive(:post_return_to_avalara)
        order.avalara_transaction.commit_avatax('ReturnInvoice', refund)
      end
    end

    describe '#commit_avatax_final' do
      it "should commit avatax final" do
        response = order.avalara_transaction.commit_avatax_final('ReturnInvoice', refund)
        expect(response).to be_kind_of(Hash)
        expect(response['ResultCode']).to eq('Success')
      end

      it 'should receive post_order_to_avalara' do
        expect(order.avalara_transaction).to receive(:post_return_to_avalara)
        order.avalara_transaction.commit_avatax_final('ReturnInvoice', refund)
      end
    end
  end
end
