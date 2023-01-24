# frozen_string_literal: true

module IrsGroups
  # Refresh EDI gateway database with cv3 family information
  class EnrollToEdidbRefresh
    include Dry::Monads[:result, :do, :try]
    include EventSource::Command
    PROCESSING_BATCH_SIZE = 5000

    def call(params)
      values               = yield validate(params)
      policies             = yield fetch_glue_policies_for_year(values)
      insurance_policies   = yield fetch_insurance_policies(policies)
      people               = yield fetch_contract_holders(insurance_policies)
      people_exclusion_set = yield build_people_to_exclude(values)
      result               = yield process(people, people_exclusion_set, values)

      Success(result)
    end

    private

    def validate(params)
      errors = []
      errors << "start_date #{params[:start_date]} is not a valid Date" unless params[:start_date].is_a?(Date)
      errors << "end_date #{params[:end_date]} is not a valid Date" unless params[:end_date].is_a?(Date)
      errors << "exclusion_list required" unless params[:exclusion_list] # array of primary hbx  ids
      @batch_size = params[:batch_size] if params[:batch_size]

      errors.empty? ? Success(params) : Failure(errors)
    end

    def fetch_glue_policies_for_year(params, collection = Policy)
      Success(collection.where(:enrollees => { '$elemMatch' => { :coverage_start => { :'$gte' => params[:start_date],
                                                                                  :'$lt' => params[:end_date] } } }))
    end

    def fetch_insurance_policies(policies)
      glue_policy_ids = policies.pluck(:eg_id)
      Success(InsurancePolicies::AcaIndividuals::InsurancePolicy.where(:policy_id.in => glue_policy_ids))
    end

    def fetch_contract_holders(insurance_policies)
      insurance_policy_ids = insurance_policies.pluck(:policy_id)
      contract_holder_ids = contract_holder_ids_query(insurance_policy_ids)
      people = People::Person.where(:id.in => contract_holder_ids.uniq)

      Success(people)
    end

    def contract_holder_ids_query(insurance_policy_ids)
      InsurancePolicies::InsuranceAgreement.collection.aggregate([{ '$lookup' =>
                                                      { from: 'insurance_policies_aca_individuals_insurance_policies',
                                                        localField: '_id',
                                                        foreignField: "insurance_agreement_id",
                                                        as: 'insurance_policies' } },
                                                                  { '$match' => {
                                                                    'insurance_policies.policy_id' =>
                                                                      { "$in" => insurance_policy_ids }
                                                                  } },
                                                                  { '$project' => {
                                                                    contract_holder_id: 1
                                                                  } }], { allowDiskUse: true }).map do |rec|
        rec["contract_holder_id"]
      end
    end

    def build_people_to_exclude(values)
      people_exclusion_set = values[:exclusion_list].inject({}) do |people_exclusion_set, primary_hbx_id|
        policies = policies_by_primary(primary_hbx_id, values)
        people_exclusion_set[primary_hbx_id] = policies.pluck(:eg_id)
        people_exclusion_set
      end

      Success(people_exclusion_set)
    end

    def policies_by_primary(primary_hbx_id, values)
      primary_person = Person.find_for_member_id(primary_hbx_id)
      return [] if primary_person.blank?

      fetch_glue_policies_for_year(values, primary_person.policies).success
    end

    def processing_batch_size
      @batch_size || PROCESSING_BATCH_SIZE
    end

    def process(people, people_exclusion_set, values)
      query_offset = 0

      while people.count > query_offset
        batched_people = people.skip(query_offset).limit(processing_batch_size)
        EnrollBatchRefreshDirector.new.call(people: batched_people.pluck(:hbx_id),
                                            people_to_exclude: people_exclusion_set,
                                            calendar_year: values[:start_date].year)
        query_offset += processing_batch_size
        p "Processed #{query_offset} people."
      end

      Success(true)
    end
  end
end
