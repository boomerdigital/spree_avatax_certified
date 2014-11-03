FactoryGirl.define do
  factory :use_code, class: Spree::AvalaraUseCodeItem do
    use_code "A"
    use_code_description "Federal government"
  end
end