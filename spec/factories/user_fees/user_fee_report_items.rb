# frozen_string_literal: true

FactoryBot.define do
  factory :user_fees_user_fee_report_item, class: 'UserFees::UserFeeReportItem' do
    sequence_value { 1 }
    hios_id { "MyString" }
  end
end
