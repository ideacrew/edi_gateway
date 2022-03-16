# frozen_string_literal: true

require 'rails_helper'
require 'shared_examples/user_fees/gdb_transactions/initial_transaction'
require 'shared_examples/user_fees/gdb_transactions/add_policy_only'
require 'shared_examples/user_fees/gdb_transactions/add_tax_household_only'
require 'shared_examples/user_fees/gdb_transactions/add_policy_and_tax_household'
require 'shared_examples/user_fees/gdb_transactions/add_enrolled_member'

RSpec.describe UserFees::GdbTransactions::PublishEnrollmentAdds do
  subject { described_class.new }
  include_context 'initial_transaction'
  include_context 'add_policy_only'
  include_context 'add_tax_household_only'
  include_context 'add_policy_and_tax_household'

  context 'Given an existing customer, assistance_year and start/end dates' do
    let(:today) { Date.today }
    let(:assistance_year) { today.year }
    let(:start_on) { Date.new(today.year, 1, 1) }
    let(:end_on) { Date.new(today.year, 12, 31) }

    # before { UserFees::Customers::Create.new.call(jetson_initial_transaction) }
    before { UserFees::Customers::Create.new.call(customer: jetson_initial_transaction[:customer]) }

    context 'and a transaction with no changes for an existing Customer' do
      let(:duplicate_transaction_result) { [] }

      it 'should not publish an event for the transaction with no changes' do
        expect(::UserFees::Customer.all.size).to eq 1
        result = subject.call(jetson_initial_transaction)
        expect(result.success?).to be_truthy
        expect(result.success).to eq duplicate_transaction_result
      end
    end

    context 'and a transaction with a new Policy for an existing Customer' do
      let(:customer_dental_policy) { jetson_add_policy_only }
      let(:policy_change_set) do
        [
          {
            exchange_assigned_id: '50837',
            insurer_assigned_id: 'HP5977621',
            rating_area_id: 'R-ME003',
            subscriber_hbx_id: '1055668',
            start_on: start_on,
            end_on: end_on,
            insurer: {
              hios_id: '96668'
            },
            product: {
              hbx_qhp_id: '96667ME031005807',
              effective_year: assistance_year,
              kind: 'dental'
            },
            marketplace_segments: [
              {
                segment: '1055668-50837-20220101',
                total_premium_amount: 0.12012e3,
                total_premium_responsibility_amount: 0.12012e3,
                start_on: start_on,
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
                      dob: Date.new(1978, 12, 19),
                      gender: 'male'
                    },
                    premium: {
                      amount: 0.4003e2
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
                      person_name: {
                        last_name: 'Jetson',
                        first_name: 'Jane'
                      },
                      ssn: '012859875',
                      dob: Date.new(1983, 9, 6),
                      gender: 'female'
                    },
                    premium: {
                      amount: 0.4007e2
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
                      person_name: {
                        last_name: 'Jetson',
                        first_name: 'Judy'
                      },
                      ssn: '012859876',
                      dob: Date.new(2007, 2, 15),
                      gender: 'female'
                    },
                    premium: {
                      amount: 0.4002e2
                    },
                    start_on: start_on,
                    end_on: end_on
                  }
                ]
              }
            ]
          }
        ]
      end

      it 'should generate an policies_added event' do
        expect(::UserFees::Customer.all.size).to eq 1
        result = subject.call(customer_dental_policy)

        expect(result.success?).to be_truthy
        expect(result.success.size).to eq 1
        expect(result.success.first.success).to be_an_instance_of Events::UserFees::EnrollmentAdds::PoliciesAdded
        expect(result.success.first.success.payload.dig(:meta, :change_set)).to eq policy_change_set
      end
    end

    context 'and a transaction with a new Tax Household for an existing Customer' do
      let(:customer_add_tax_household) { jetson_add_tax_household_only }
      let(:tax_household_change_set) do
        [
          {
            assistance_year: assistance_year,
            aptc_amount: 850.0.to_d,
            csr: 0,
            exchange_assigned_id: '6161',
            start_on: start_on,
            end_on: end_on
          }
        ]
      end

      it 'should generate an tax_households_added event' do
        expect(::UserFees::Customer.all.size).to eq 1
        result = subject.call(customer_add_tax_household)

        expect(result.success?).to be_truthy
        expect(result.success.size).to eq 1
        expect(result.success.first.success).to be_an_instance_of Events::UserFees::EnrollmentAdds::TaxHouseholdsAdded
        expect(result.success.first.success.payload.dig(:meta, :change_set)).to eq tax_household_change_set
      end
    end

    context 'and a transaction with both a new Policy and new Tax Household for an existing Customer' do
      let(:customer_add_tax_household) { jetson_add_policy_and_tax_household }
      let(:tax_household_change_set) do
        [{ aptc_amount: 0.85e3, csr: 0, end_on: end_on, exchange_assigned_id: 6161, start_on: start_on }]
      end
      let(:policy_and_thh_class_names) do
        %w[Events::UserFees::EnrollmentAdds::PoliciesAdded Events::UserFees::EnrollmentAdds::TaxHouseholdsAdded]
      end

      it 'should generate an policies_added and tax_houeholds added events' do
        expect(::UserFees::Customer.all.size).to eq 1
        result = subject.call(customer_add_tax_household)

        expect(result.success?).to be_truthy
        expect(result.success.size).to eq 2

        expect(
          result
            .success
            .reduce([]) { |list, monad|
              list << monad.success.class.name
              list
            }
        ).to eq policy_and_thh_class_names
      end
    end
  end
end
