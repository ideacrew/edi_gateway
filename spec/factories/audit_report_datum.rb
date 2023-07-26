# frozen_string_literal: true

FactoryBot.define do
  factory :audit_report_datum do
    subscriber_id { '12345' }
    status { 'pending' }
    payload { "test" }
    hios_id { '12345' }
  end
end
