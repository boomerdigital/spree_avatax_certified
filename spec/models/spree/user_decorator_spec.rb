require 'spec_helper'

describe Spree.user_class do
  it { should have_one :avalara_use_code_item }
end
