# frozen_string_literal: true

require 'bigdecimal'
require 'bigdecimal/util'

RSpec.shared_context 'customer_params' do
  let(:is_active) { true }
  let(:moment) { DateTime.now }
  let(:timestamps) { { created_at: moment, modified_at: moment } }

  # Member
  let(:hbx_id) { '1138345' }
  let(:subscriber_hbx_id) { hbx_id }
  let(:person_name) { { first_name: 'George', last_name: 'Jetson' } }
  let(:member) { { hbx_id: hbx_id, subscriber_hbx_id: subscriber_hbx_id, person_name: person_name } }

  # Product
  let(:hbx_qhp_id) { '96667ME031005806' }
  let(:effective_year) { 2022 }
  let(:kind) { 'health' }
  let(:product) { { hbx_qhp_id: hbx_qhp_id, effective_year: effective_year, kind: kind } }

  # Premium
  let(:insured_age) { 33 }
  let(:amount) { 875.22.to_d }
  let(:premium) { { insured_age: insured_age, amount: amount } }

  # Enrolled Member
  let(:start_on) { Date.new(2022, 2, 1) }
  let(:enrolled_member) { { member: member, premium: premium, start_on: start_on } }
  let(:enrolled_members) { [enrolled_member] }

  # Insurer
  let(:hios_id) { '96667' }
  let(:insurer) { { hios_id: hios_id } }

  # Policy
  let(:exchange_assigned_id) { '68576' }
  let(:rating_area_id) { 'R-ME001' }
  let(:policy) do
    {
      exchange_assigned_id: exchange_assigned_id,
      marketplace_segments: marketplace_segments,
      subscriber_hbx_id: subscriber_hbx_id,
      insurer: insurer,
      product: product,
      rating_area_id: rating_area_id,
      start_on: start_on
    }
  end
  let(:policies) { [policy] }

  # Marketplace Segment
  let(:policy_id) { '68576' }
  let(:segment) { [subscriber_hbx_id, policy_id, start_on.strftime('%Y%m%d')].join('-') }
  let(:marketplace_segment) do
    {
      subscriber_hbx_id: subscriber_hbx_id,
      start_on: start_on,
      segment: segment,
      enrolled_members: enrolled_members,
      total_premium_amount: amount,
      total_premium_responsibility_amount: amount
    }
  end
  let(:marketplace_segments) { [marketplace_segment] }

  # Tax Household
  let(:tax_household) { { exchange_assigned_id: 6161, aptc_amount: 585.6.to_d, start_on: start_on } }
  let(:tax_households) { [tax_household] }

  # InsuranceCoverage
  let(:insurance_coverage) do
    { hbx_id: hbx_id, tax_households: tax_households, policies: policies, is_active: is_active }
  end

  # All Attributes in Transaction form
  let(:transaction) do
    {
      # customer_id: '1055668',
      hbx_id: '1055668',
      last_name: 'Jetson',
      first_name: 'George',
      customer_role: 'subscriber',
      is_active: true,
      account: {
        number: '1100001'.to_i,
        name: 'Accounts Receivable',
        kind: 'asset',
        is_active: true
      },
      insurance_coverage: {
        hbx_id: '1055668',
        tax_households: [
          { exchange_assigned_id: 6161, aptc_amount: 850.0.to_d, csr: 0, start_on: '20220101', end_on: '20221231' }
        ],
        policies: [
          {
            exchange_assigned_id: '50836',
            insurer_assigned_id: 'HP5977620',
            rating_area_id: 'R-ME003',
            subscriber_hbx_id: '1055668',
            start_on: '20220101',
            end_on: '20221231',
            insurer: {
              hios_id: '96667'
            },
            product: {
              hbx_qhp_id: '96667ME031005806',
              effective_year: 2022,
              kind: 'health'
            },
            marketplace_segments: [
              {
                segment: '1055668-50836-20220101',
                total_premium_amount: 1104.58.to_d,
                total_premium_responsibility_amount: 254.58.to_d,
                start_on: '20220101',
                enrolled_members: [
                  {
                    member: {
                      relationship_code: '1:18',
                      is_subscriber: true,
                      subscriber_hbx_id: '1055668',
                      hbx_id: '1055668',
                      insurer_assigned_id: 'HP597762000',
                      insurer_assigned_subscriber_id: 'HP597762000',
                      person_name: {
                        last_name: 'Jetson',
                        first_name: 'George'
                      },
                      ssn: '012859874',
                      dob: '19781219',
                      gender: 'male',
                      tax_household_id: 6161
                    },
                    premium: {
                      amount: 423.86.to_d
                    },
                    start_on: '20220101',
                    end_on: '20221231'
                  },
                  {
                    member: {
                      relationship_code: '4:19',
                      is_subscriber: false,
                      subscriber_hbx_id: '1055668',
                      hbx_id: '1055678',
                      insurer_assigned_id: 'HP597762002',
                      insurer_assigned_subscriber_id: 'HP597762000',
                      person_name: {
                        last_name: 'Jetson',
                        first_name: 'Jane'
                      },
                      ssn: '012859875',
                      dob: '19830906',
                      gender: 'female',
                      tax_household_id: 6161
                    },
                    premium: {
                      amount: 410.06.to_d
                    },
                    start_on: '20220101',
                    end_on: '20221231'
                  },
                  {
                    member: {
                      relationship_code: '2:01',
                      is_subscriber: false,
                      subscriber_hbx_id: '1055668',
                      hbx_id: '1055689',
                      insurer_assigned_id: 'HP597762001',
                      insurer_assigned_subscriber_id: 'HP597762000',
                      person_name: {
                        last_name: 'Jetson',
                        first_name: 'Judy'
                      },
                      ssn: '012859876',
                      dob: '20070215',
                      gender: 'female',
                      tax_household_id: 6161,
                      emails: 'jetsons@example.com'
                    },
                    premium: {
                      amount: 270.66.to_d
                    },
                    start_on: '20220101',
                    end_on: '20221231'
                  }
                ]
              }
            ]
          }
        ],
        is_active: true
      }
    }
  end
end
