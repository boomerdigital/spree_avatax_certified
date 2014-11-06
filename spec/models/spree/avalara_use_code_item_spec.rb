require 'spec_helper'

describe Spree::AvalaraUseCodeItem, type: :model do
  it { should belong_to :user }
end