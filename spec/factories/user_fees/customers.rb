# frozen_string_literal: true

FactoryBot.define do
  factory :user_fees_customer, class: 'UserFees::Customer' do
    first_name { "MyString" }
    last_name { "MyString" }
    hbx_id { "MyString" }
    customer_role { "MyString" }
    is_active { false }
    insurance_coverage_id { "MyString" }
  end
end
