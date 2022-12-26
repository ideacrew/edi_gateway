# frozen_string_literal: true

# AcaEntities::Ledger::Contracts::PolicyContract.new.call(new_state)

def new_state
  {
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
        total_premium_amount: 0.110458e4,
        total_premium_responsibility_amount: 0.25458e3,
        start_on: 'Sat, 01 Jan 2022',
        enrolled_members: [
          {
            member: {
              hbx_id: '1055668',
              insurer_assigned_id: 'HP597762000',
              subscriber_hbx_id: '1055668',
              insurer_assigned_subscriber_id: 'HP597762000',
              person_name: {
                first_name: 'George',
                last_name: 'Jetson'
              },
              ssn: '012859874',
              dob: 'Tue, 19 Dec 1978',
              gender: 'male',
              tax_household_id: '6161',
              relationship_code: '1:18',
              is_subscriber: true
            },
            premium: {
              amount: 0.42386e3
            },
            start_on: 'Sat, 01 Jan 2022',
            end_on: 'Sat, 31 Dec 2022'
          },
          {
            member: {
              hbx_id: '1055678',
              insurer_assigned_id: 'HP597762002',
              subscriber_hbx_id: '1055668',
              insurer_assigned_subscriber_id: 'HP597762000',
              person_name: {
                first_name: 'Jane',
                last_name: 'Jetson'
              },
              ssn: '012859875',
              dob: 'Tue, 06 Sep 1983',
              gender: 'female',
              tax_household_id: '6161',
              relationship_code: '4:19',
              is_subscriber: false
            },
            premium: {
              amount: 0.41006e3
            },
            start_on: 'Sat, 01 Jan 2022',
            end_on: 'Sat, 31 Dec 2022'
          },
          {
            member: {
              hbx_id: '1055689',
              insurer_assigned_id: 'HP597762001',
              subscriber_hbx_id: '1055668',
              insurer_assigned_subscriber_id: 'HP597762000',
              person_name: {
                first_name: 'Judy',
                last_name: 'Jetson'
              },
              ssn: '012859876',
              dob: 'Thu, 15 Feb 2007',
              gender: 'female',
              tax_household_id: '6161',
              relationship_code: '2:01',
              is_subscriber: false
            },
            premium: {
              amount: 0.27066e3
            },
            start_on: 'Sat, 01 Jan 2022',
            end_on: 'Sat, 31 Dec 2022'
          }
        ]
      }
    ],
    exchange_assigned_id: '50836',
    insurer_assigned_id: 'HP5977620',
    subscriber_hbx_id: '1055668',
    rating_area_id: 'R-ME003',
    start_on: 'Sat, 01 Jan 2022',
    end_on: 'Sat, 31 Dec 2022'
  }
end
