# frozen_string_literal: true

FactoryBot.define do
  factory :enrollee, class: Enrollee do
    sequence(:m_id, &:to_s)
    ben_stat { 'active' }
    emp_stat { 'active' }
    rel_code { 'self' }
    ds { false }
    pre_amt { '666.66' }
    sequence(:c_id, &:to_s)
    sequence(:cp_id, &:to_s)
    coverage_start { Date.today }
    coverage_end { nil }
    coverage_status { 'active' }
  end
end
