require 'spec_helper'

describe Spree::AvalaraEntityUseCode, type: :model do
  it { should have_many :users }
end