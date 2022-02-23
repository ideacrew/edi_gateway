# frozen_string_literal: true

RSpec.shared_context 'customer_account_params' do
  let(:transaction) do
    {
      customer: {
        relationship_code: '1:18',
        is_subscriber: true,
        hbx_id: '1055668',
        subscriber_hbx_id: '1055668',
        insurer_assigned_id: 'HP597762000',
        insurer_assigned_subscriber_id: 'HP597762000',
        person_name: {
          last_name: 'Jetson',
          first_name: 'George'
        },
        ssn: '012859874',
        dob: '19781219',
        gender: 'male',
        tax_household_id: '100'
      },
      # customer_id: '1055668',
      customer_role: 'subscriber',
      tax_households: [{ id: '100', aptc_amount: 850.0, csr: 0, start_on: '20220101', end_on: '20221231' }],
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
              total_premium_amount: 1104.58,
              total_premium_responsibility_amount: 254.58,
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
                    tax_household_id: '100'
                  },
                  premium: {
                    amount: 423.86
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
                    tax_household_id: '100'
                  },
                  premium: {
                    amount: 410.06
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
                    tax_household_id: '100',
                    emails: 'jetsons@example.com'
                  },
                  premium: {
                    amount: 270.66
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
  end
end
