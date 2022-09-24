# frozen_string_literal: true

require 'shared_examples/edi_database/transactions/initial_transaction'
require 'shared_examples/edi_database/transactions/termed_enrollment_transaction'
require 'shared_examples/edi_database/transactions/add_tax_household_only'
require 'shared_examples/edi_database/transactions/termed_tax_household_transaction'
require 'shared_examples/edi_database/transactions/add_policy_only'
require 'shared_examples/edi_database/transactions/termed_policy_transaction'
require 'shared_examples/edi_database/transactions/add_policy_and_tax_household'

RSpec.describe EdiDatabase::Transactions::PublishEnrollmentTerminations, db_clean: :before do
  subject { described_class.new }
  include_context 'initial_transaction'
  include_context 'termed_enrollment_transaction'

  include_context 'add_tax_household_only'
  include_context 'termed_tax_household_transaction'

  include_context 'add_policy_only'
  include_context 'termed_policy_transaction'

  include_context 'add_policy_and_tax_household'

  context 'Given an assistance_year and start/end dates' do
    let(:today) { Date.today }
    let(:assistance_year) { today.year }
    let(:start_on) { Date.new(today.year, 1, 1) }
    let(:end_on) { Date.new(today.year, 12, 31) }

    context 'and an existing Customer with insurance_coverage' do
      let(:uuid_regex) { /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/ }
      let(:existing_customer) { { customer: jetson_initial_transaction[:customer] } }
      let(:hbx_id) { existing_customer[:customer][:hbx_id] }

      before { UserFees::Customers::Create.new.call(existing_customer) }

      it 'a transaction terminating that insurance_coverage should generate an enrollment_terminated event' do
        expect(::UserFees::Customer.all.size).to eq 1
        result = subject.call(jetson_termed_enrollment_transaction)

        expect(result.success?).to be_truthy
        expect(::UserFees::Customer.all.size).to eq 1
        expect(result.success.size).to eq 1
        expect(result.success.first).to be_an_instance_of Events::UserFees::EnrollmentTerminations::EnrollmentTerminated

        expect(result.success.first.payload.dig(:meta, :change_set)).not_to be_empty
        expect(result.success.first.payload.dig(:meta, :correlation_id)).to match uuid_regex
        expect(result.success.first.payload.dig(:old_state, :customer, :is_active)).to be_truthy
        expect(result.success.first.payload.dig(:new_state, :customer, :hbx_id)).to eq hbx_id
        expect(result.success.first.payload.dig(:new_state, :customer, :insurance_coverage, :is_active)).to be_falsey
      end

      context 'and a transaction with no changes for an existing Customer' do
        let(:duplicate_transaction_result) { nil }

        # before { UserFees::Customers::Create.new.call(customer: jetson_initial_transaction[:customer]) }

        xit 'should not publish an event for the transaction with no changes' do
          expect(::UserFees::Customer.all.size).to eq 1
          result = subject.call(jetson_initial_transaction)

          expect(result.success?).to be_truthy
          expect(result.success).to eq duplicate_transaction_result
        end
      end
    end

    context 'and a transaction terminating a Policy for an existing Customer' do
      let(:customer_with_policy) { jetson_add_policy_only }
      let(:term_policy_transaction) { jetson_term_policy_only }
      let(:early_end_on) { Date.new(moment.to_date.year, 3, 31) }

      let(:policy_change_set) do
        [
          {
            exchange_assigned_id: '50837',
            insurer_assigned_id: 'HP5977621',
            rating_area_id: 'R-ME003',
            subscriber_hbx_id: '1055668',
            start_on: start_on,
            end_on: early_end_on,
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
                total_premium_amount: 120.12.to_d,
                total_premium_responsibility_amount: 120.12.to_d,
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
                      amount: 40.03.to_d
                    },
                    start_on: start_on,
                    end_on: early_end_on
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
                      amount: 40.07.to_d
                    },
                    start_on: start_on,
                    end_on: early_end_on
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
                      amount: 40.02.to_d
                    },
                    start_on: start_on,
                    end_on: early_end_on
                  }
                ]
              }
            ]
          }
        ]
      end

      before { UserFees::Customers::Create.new.call(customer: customer_with_policy[:customer]) }

      xit 'should generate an enrollment_policy_terminated event' do
        expect(::UserFees::Customer.all.size).to eq 1
        result = subject.call(jetson_term_policy_only)

        expect(result.success?).to be_truthy
        expect(result.success.size).to eq 1
        expect(
          result.success.first.success
        ).to be_an_instance_of Events::UserFees::EnrollmentTerminations::PoliciesTerminated
        expect(result.success.first.success.payload.dig(:meta, :change_set)).to eq policy_change_set
      end
    end

    context 'and a transaction terminating a Tax Household for an existing Customer' do
      let(:customer_with_tax_household) { jetson_add_tax_household_only }
      let(:term_tax_household_transaction) { jetson_term_tax_household_only }
      let(:early_end_on) { Date.new(moment.to_date.year, 3, 31) }

      let(:tax_household_change_set) do
        [
          {
            assistance_year: assistance_year,
            aptc_amount: 850.0.to_d,
            csr: 0,
            exchange_assigned_id: '6161',
            start_on: start_on,
            end_on: early_end_on
          }
        ]
      end

      before { UserFees::Customers::Create.new.call(customer: customer_with_tax_household[:customer]) }

      xit 'should generate an enrollment_dependent_terminated event' do
        expect(::UserFees::Customer.all.size).to eq 1
        result = subject.call(term_tax_household_transaction)

        expect(result.success?).to be_truthy
        expect(result.success.size).to eq 2
        expect(
          result.success.first.success
        ).to be_an_instance_of Events::UserFees::EnrollmentTerminations::TaxHouseholdsTerminated

        expect(result.success.first.success.payload.dig(:meta, :change_set)).to eq tax_household_change_set
      end
    end

    context 'and a transaction with both a new Policy and new Tax Household for an existing Customer' do
      let(:customer_add_tax_household) { jetson_add_policy_and_tax_household }
      let(:tax_household_change_set) do
        [{ aptc_amount: 850.0.to_d, csr: 0, end_on: end_on, exchange_assigned_id: '6161', start_on: start_on }]
      end
      let(:policy_and_thh_class_names) do
        %w[
          Events::UserFees::EnrollmentAdds::PoliciesTerminated
          Events::UserFees::EnrollmentAdds::TaxHouseholdsTerminated
        ]
      end

      before { UserFees::Customers::Create.new.call(customer: jetson_initial_transaction[:customer]) }

      xit 'should generate an enrollment_dependent_terminated event' do
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
