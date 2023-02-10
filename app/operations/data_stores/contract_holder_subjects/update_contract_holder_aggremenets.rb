# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module DataStores
  module ContractHolderSubjects
    # Operation to create or update ContractHolderSubjects
    class UpdateContractHolderAggrements
      send(:include, Dry::Monads[:result, :do])
      include EventSource::Command

      def call(params)
        values          = yield validate(params)
        subject         = yield find_contract_holder_subject(values)
        contract_holder = yield find_or_create_contract_holder(subject)
        is_group        = yield find_or_create_irs_group(subject)
        aggrements      = yield create_or_update_insurance_agreemenets(subject, contract_holder, irs_group)
        family_cv       = yield process_irs_group_updates(subject)

        Success(subject)
      end

      private 

      def validate(params)
        params[:sync_job_id]
        return Failure('sync_job id expected') unless params[:sync_job_id]
        return Failure('primary person hbx id expected') unless params[:primary_person_hbx_id]
         
        Success(values)
      end

      def find_contract_holder_subject(values)
        sync_job = DataStores::ContractHolderSyncJob.find(values[:sync_job_id])
        subject = sync_job.subjects.by_primary_hbx_id(values[:primary_person_hbx_id]).first

        Success(subject)
      end

      def find_or_create_contract_holder(subject)
        glue_person = Person.where(authority_member_id: subject.primary_person_hbx_id).first

        edidb_person = People::Persons::Find.new.call({ hbx_id: subject.authority_member_id })
        return edidb_person if edidb_person.success?
  
        People::Persons::Create.new.call(person: glue_person)
      end

      def find_or_create_irs_group(glue_policy)
        # date = glue_policy.subscriber.coverage_start.beginning_of_year ??
        # return Success({} )if non_eligible_policy(glue_policy)
  
        glue_person  = find_person_from_glue_policy(glue_policy)
        irs_group_id = construct_irs_group_id(date.year.to_s.last(2), glue_person.authority_member_id)
  
        irs_group = InsurancePolicies::AcaIndividuals::IrsGroups::Find
                    .new.call({ scope_name: :by_irs_group_id, criterion: irs_group_id })
        return irs_group if irs_group.success?
  
        InsurancePolicies::AcaIndividuals::IrsGroups::Create.new.call({ irs_group_id: irs_group_id,
                                                                        start_on: date })
      end

      def create_or_update_insurance_agreemenets(subject, contract_holder, irs_group)
        policy_ids = subject.subscriber_policies + subject.responsible_party_policies

        Policy.where(:eg_id.in => policy_ids.uniq).each do |policy|
          IrsGroups::CreateOrUpdateInsuranceAgreement.new.call(
            contract_holder: contract_holder,
            irs_group: irs_group,
            policy: policy
          )
        end
      end

      def process_irs_group_updates(subject)
        IrsGroups::SeedIrsGroup.new.call(
          payload: subject.response_event.body
        )
      end

      def construct_irs_group_id(year, hbx_id)
        total_length_excluding_year = 14
        hbx_id_number = format("%0#{total_length_excluding_year}d", hbx_id)
        year + hbx_id_number
      end
    end
  end
end



#    Node will process subject 

#    - create contract holder 
#    - create irs_group
#    - call operation to create insurance agreement for each policies create

#   -> Store policies 

#   operation: IrsGroups::CreateOrUpdateInsuranceAgreement
#   input: policy_id

#   make sure to create person and irs group first before triggering async calls for policy persistance
#   make sure policies persisted successfully before triggering persistance of family cv 

#   create inadvance following and pass it to above operation
#     person_hash = yield persist_contract_holder(glue_policy)
#     irs_group_hash = yield persist_irs_group(glue_policy)

#   -> Family CV persistance 
    
#   Remove calendar year dependency 