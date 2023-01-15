# frozen_string_literal: true

FactoryBot.define do
  factory :irs_group, class: InsurancePolicies::AcaIndividuals::IrsGroup do
    start_on { Date.today }
    end_on { nil }
    sequence(:irs_group_id) { |_n| "2200000001000533" }
  end
end
