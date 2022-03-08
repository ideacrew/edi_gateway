# frozen_string_literal: true

require 'bigdecimal'
require 'bigdecimal/util'

RSpec.shared_context 'add_policy_and_tax_household' do
  let(:jetson_add_policy_and_tax_household) do
    {
      meta: {
        code: 1,
        application_extract_time: 'Wed, 01 Mar 2022 12:05:52 -0500',
        policy_maintenance_time: 'Wed, 01 Mar 2022 12:05:52 -0500'
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
            },
            {
              exchange_assigned_id: '50837',
              insurer_assigned_id: 'HP5977621',
              rating_area_id: 'R-ME003',
              subscriber_hbx_id: '1055668',
              start_on: '20220101',
              end_on: '20221231',
              insurer: {
                hios_id: '96668'
              },
              product: {
                hbx_qhp_id: '96667ME031005807',
                effective_year: 2022,
                kind: 'dental'
              },
              marketplace_segments: [
                {
                  segment: '1055668-50837-20220101',
                  total_premium_amount: 120.12.to_d,
                  total_premium_responsibility_amount: 120.12.to_d,
                  start_on: '20220101',
                  enrolled_members: [
                    {
                      member: {
                        relationship_code: '1:18',
                        is_subscriber: true,
                        subscriber_hbx_id: '1055668',
                        hbx_id: '1055668',
                        person_name: {
                          last_name: 'Jetson',
                          first_name: 'George'
                        },
                        ssn: '012859874',
                        dob: '19781219',
                        gender: 'male'
                      },
                      premium: {
                        amount: 40.03.to_d
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
                        person_name: {
                          last_name: 'Jetson',
                          first_name: 'Jane'
                        },
                        ssn: '012859875',
                        dob: '19830906',
                        gender: 'female'
                      },
                      premium: {
                        amount: 40.07.to_d
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
                        person_name: {
                          last_name: 'Jetson',
                          first_name: 'Judy'
                        },
                        ssn: '012859876',
                        dob: '20070215',
                        gender: 'female',
                        emails: 'jetsons@example.com'
                      },
                      premium: {
                        amount: 40.02.to_d
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
    }
  end
end
