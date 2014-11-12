require 'spec_helper'

describe Spree.user_class do
  it { should belong_to :avalara_entity_use_code }
end
