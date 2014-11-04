require 'rails_helper'

describe Spree::AvalaraTransaction do
  it { should belong_to :order }
  it { should belong_to :return_authorization }

  it { should have_one :adjustment }

  it { should validate_presence_of :order }
end
