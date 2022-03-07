# frozen_string_literal: true

require 'rails_helper'
require 'shared_examples/user_fees/gdb_transactions/initial_transaction'
require 'shared_examples/user_fees/gdb_transactions/add_policy'
# require 'shared_examples/user_fees/gdb_transactions/add_tax_household'
require 'shared_examples/user_fees/gdb_transactions/add_enrolled_member'

RSpec.describe UserFees::GdbTransactions::CheckAdditionTransaction do
  subject { described_class.new }
  include_context 'initial_transaction'
  include_context 'add_policy'
  include_context 'add_enrolled_member'

  context 'Given a transaction for a new Customer ' do
    let(:customer) { jetson_initial_transaction }
    let(:old_state) { { customer: {} } }
    let(:hbx_id) { customer.dig(:customer, :hbx_id) }

    it 'should generate an initial_enrollment_added event' do
      result = subject.call(customer)

      expect(result.success?).to be_truthy
      expect(result.success.size).to eq 1
      expect(result.success.first.success).to be_an_instance_of Events::UserFees::EnrollmentAdds::InitialEnrollmentAdded
      expect(result.success.first.success.payload[:old_state]).to eq old_state
      expect(result.success.first.success.payload.dig(:meta, :change_set)).to eq Hash.new
      expect(result.success.first.success.payload.dig(:new_state, :customer, :hbx_id)).to eq hbx_id
    end
  end

  context 'Given a transaction with a new policy for an existing Customer' do
    let(:customer_dental_policy) { jetson_add_dental_policy }
    let(:policy_change_set) do
      [
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
              total_premium_amount: 0.12012e3,
              total_premium_responsibility_amount: 0.12012e3,
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
                    amount: 0.4003e2
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
                    amount: 0.4007e2
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
                    amount: 0.4002e2
                  },
                  start_on: '20220101',
                  end_on: '20221231'
                }
              ]
            }
          ]
        }
      ]
    end

    before { UserFees::Customers::Create.new.call(customer: jetson_initial_transaction[:customer]) }

    it 'should generate an enrollment_policy_added event' do
      expect(::UserFees::Customer.all.size).to eq 1
      result = subject.call(customer_dental_policy)

      expect(result.success?).to be_truthy
      expect(result.success.size).to eq 1
      expect(result.success.first.success).to be_an_instance_of Events::UserFees::EnrollmentAdds::PoliciesAdded
      expect(result.success.first.success.payload.dig(:meta, :change_set)).to eq policy_change_set
    end
  end

  context 'Given a transaction with a new enrolled member for an existing Customer' do
    let(:customer_add_dependent) { jetson_add_dependent }

    it 'should generate an enrollment_dependent_added event'
  end
end
