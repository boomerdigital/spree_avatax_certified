require 'spec_helper'

describe Spree::Refund, type: :model do

  it { should have_one :avalara_transaction }

end