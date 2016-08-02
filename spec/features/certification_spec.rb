require 'spec_helper'

describe "Certification" do
  let!(:avalara_order) { create(:avalara_order, line_items_count: 2, line_items_quantity: 2) }
  let(:unique_ship_address) { create(:address, firstname: 'Jimmie', lastname: 'Johnson', address1: '3366 Speedway Blvd', city: 'Lincoln', state_name: 'Alabama', zipcode: 35096) }
  let!(:order) { create(:order_with_line_items, state: 'delivery', user: nil, ship_address: unique_ship_address, email: 'acreilly3@gmail.com') }
  let(:use_code) { create(:avalara_entity_use_code) }

  context 'Transactions have been voided/cancelled.' do
    before do
      order.avalara_capture_finalize
      @response = order.cancel_avalara
    end

    it 'should be successful' do
      expect(@response["ResultCode"]).to eq("Success")
    end
  end

  context 'Transactions have been committed.' do
    it 'commits an order' do
      res = order.avalara_capture_finalize

      expect(res['ResultCode']).to eq('Success')
    end
  end

  context 'Exempt sales should be reflected in the test data through use of ExemptionNo or CustomerUsageType.' do
    before do
      avalara_order.user.update_attributes(avalara_entity_use_code: use_code)
    end

    it 'does not add additional tax' do
      expect(avalara_order.avalara_transaction.commit_avatax('SalesInvoice')['TotalTax']).to eq('0')
    end
  end

  context 'return orders' do
    let(:refund_reason) { create(:refund_reason) }
    let(:reimbursement) { create(:reimbursement) }
    let(:order) { reimbursement.order }
    let(:refund) { build(:refund, payment: order.payments.first, amount: BigDecimal.new(10), reason: refund_reason, transaction_id: nil, reimbursement: reimbursement) }

    before do
      order.update_attributes(completed_at: 2.days.ago)
      order.avalara_capture_finalize
      order.reload
    end

    describe '#commit_avatax_final' do
      it 'should commit avatax final' do
        response = order.avalara_transaction.commit_avatax_final('ReturnInvoice', refund)

        expect(response).to be_kind_of(Hash)
        expect(response['ResultCode']).to eq('Success')
      end
    end
  end
end


#### Certification Requirements to pass ####

# Transactions have been voided/cancelled.
# Transactions have been committed.
# Test transactions had meaningful document codes.
# Test transactions had meaningful customer code values.
# Transactions with more than one line item were tested.
# Exempt sales should be reflected in the test data through use of ExemptionNo or CustomerUsageType.
# Returns were tested with negative amounts and TaxDate overrides.
# Quantites should always represent positive values.
# Multiple quantity lines were tested.
# Shipping charges were reflected in the test data as separate line items.
# Multiple item codes were tested.
# Multiple descriptions were tested.
# Multiple tax codes were tested.
# A variety of addresses were used for testing.
