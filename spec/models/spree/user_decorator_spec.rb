require 'spec_helper'

describe Spree.user_class do
  it { should belong_to :avalara_use_code_item }
end
