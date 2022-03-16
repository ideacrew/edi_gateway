# frozen_string_literal: true

require 'bigdecimal'
require 'bigdecimal/util'

RSpec.shared_context 'initial_transaction' do
  let(:moment) { DateTime.now }
  let(:start_on) { Date.new(moment.to_date.year, 1, 1) }
  let(:end_on) { Date.new(moment.to_date.year, 12, 31) }

  let(:jetson_initial_transaction) do
    {
      meta: {
        transaction_header: {
          code: 1,
          application_extract_time: moment,
          policy_maintenance_time: moment
        }
      },
      customer: {
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
          policies: [
            {
              exchange_assigned_id: '50836',
              insurer_assigned_id: 'HP5977620',
              rating_area_id: 'R-ME003',
              subscriber_hbx_id: '1055668',
              start_on: start_on,
              end_on: end_on,
              insurer: {
                hios_id: '96667'
              },
              product: {
                hbx_qhp_id: '96667ME031005806',
                effective_year: moment.year,
                kind: 'health'
              },
              marketplace_segments: [
                {
                  segment: '1055668-50836-20220101',
                  total_premium_amount: 1104.58.to_d,
                  total_premium_responsibility_amount: 254.58.to_d,
                  start_on: start_on,
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
                        tax_household_id: '6161'
                      },
                      premium: {
                        amount: 423.86.to_d
                      },
                      start_on: start_on,
                      end_on: end_on
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
                        tax_household_id: '6161'
                      },
                      premium: {
                        amount: 410.06.to_d
                      },
                      start_on: start_on,
                      end_on: end_on
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
                        tax_household_id: '6161',
                        emails: 'jetsons@example.com'
                      },
                      premium: {
                        amount: 270.66.to_d
                      },
                      start_on: start_on,
                      end_on: end_on
                    }
                  ]
                }
              ]
            }
          ],
          is_active: true
        }
      }
    }
  end
end
