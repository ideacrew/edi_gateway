# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

# move to insurance policies contract holder
module InsurancePolicies
  module ContractHolders
    # Operation to create or update ContractHolderSubjects
    class CreateOrUpdate
      send(:include, Dry::Monads[:result, :do])
      include EventSource::Command

      def call(params)
        values = yield validate(params)
        contract_holder = yield find_or_create_contract_holder(values)
        irs_group = yield find_or_create_irs_group(values)
        _agreements = yield create_or_update_insurance_agreements(values, contract_holder, irs_group)
        _output = yield process_irs_group_updates(values)

        Success(contract_holder)
      end

      private

      def validate(params)
        return Failure('subject expected') unless params[:subject]
        return Failure('response event not found on subject') unless params[:subject].response_event

        params[:family_cv] = JSON.parse(params[:subject].response_event&.body, symbolize_names: true)

        Success(params)
      end

      # currenty_entity = find or initialize entity
      # compare incoming entity from input params
      # compare incoming entity with current
      # if there's no differece we don't update
      # if there's is a difference - can we update entity?

      def find_or_create_contract_holder(values)
        edidb_person = People::Persons::Find.new.call({ hbx_id: values[:subject].primary_person_hbx_id })
        return edidb_person if edidb_person.success?

        glue_person = Person.where(authority_member_id: values[:subject].primary_person_hbx_id).first
        People::Persons::Create.new.call(person: glue_person)
      end

      def find_or_create_irs_group(values)
        irs_group_id = construct_irs_group_id('22', values[:subject].primary_person_hbx_id)

        irs_group =
          InsurancePolicies::AcaIndividuals::IrsGroups::Find.new.call(
            { scope_name: :by_irs_group_id, criterion: irs_group_id }
          )
        return irs_group if irs_group.success?

        InsurancePolicies::AcaIndividuals::IrsGroups::Create.new.call(
          irs_group_id: irs_group_id,
          family_hbx_assigned_id: values[:family_cv][:hbx_id],
          start_on: Date.today # NOTE: when does irs group end. death?
        )
      end

      def create_or_update_insurance_agreements(values, contract_holder, irs_group)
        policy_ids = values[:subject].subscriber_policies + values[:subject].responsible_party_policies

        # when there are multiple policies, system may partially load policies. this need to verified.
        #  ex. when 3 policies passed, first two are processed successfully and it may fail on 3rd one.
        results =
          Policy
          .where(:eg_id.in => policy_ids.uniq)
          .collect do |policy|
            IrsGroups::CreateOrUpdateInsuranceAgreement.new.call(
              contract_holder_hash: contract_holder,
              irs_group_hash: irs_group,
              policy: policy
            )
          end
        if results.any?(&:failure?)
          errors = results.select(&:failure?).map { |output| output.failure.errors.to_h }
          return Failure(errors)
        end
        Success(true)
      end

      def process_irs_group_updates(values)
        IrsGroups::SeedIrsGroup.new.call(payload: values[:family_cv])
      end

      def construct_irs_group_id(year, hbx_id)
        total_length_excluding_year = 14
        hbx_id_number = format("%0#{total_length_excluding_year}d", hbx_id)
        year + hbx_id_number
      end
    end
  end
end
