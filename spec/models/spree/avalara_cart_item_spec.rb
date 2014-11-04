require 'rails_helper'

describe Spree::AvalaraCartItem do
  it { should belong_to :line_item }
  it { should belong_to :avalara_transaction }

  it { should validate_presence_of :index }
  it { should validate_presence_of :tic }
  it { should validate_presence_of :sku }
  it { should validate_presence_of :price }
  it { should validate_presence_of :quantity }

  it { should have_db_index :line_item_id }
  it { should have_db_index :avalara_transaction_id }

  it { accept_nested_attributes_for :line_item }

  its(:to_hash) { should be_kind_of Hash }
end
