require 'spec_helper'

describe Spree::AvalaraUseCodeItem, type: :model do
  it { should have_many :users }
end