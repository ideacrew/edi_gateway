# frozen_string_literal: true

module IrsGroups
  # Refresh EDI gateway database with cv3 family information
  class EnrollRefresh
    include Dry::Monads[:result, :do, :try]
    include EventSource::Command
    require 'dry/monads'
    require 'dry/monads/do'

    def call(params)
      validated_params = yield validate(params)
      policies = yield fetch_glue_policies_for_year(validated_params)
      insurance_policies = yield fetch_insurance_policies(policies)
      contract_holder_ids = yield fetch_contract_holders(insurance_policies)
      result = yield fetch_cv3_family(contract_holder_ids, params)
      Success(result)
    end

    private

    def validate(params)
      errors = []
      errors << "start_date #{params[:start_date]} is not a valid Date" unless params[:start_date].is_a?(Date)
      errors << "end_date #{params[:end_date]} is not a valid Date" unless params[:end_date].is_a?(Date)

      errors.empty? ? Success(params) : Failure(errors)
    end

    def fetch_glue_policies_for_year(params)
      Success(Policy.where(:enrollees => { '$elemMatch' => { :coverage_start => { :'$gte' => params[:start_date],
                                                                                  :'$lt' => params[:end_date] } } }))
    end

    def fetch_insurance_policies(policies)
      glue_policy_ids = policies.pluck(:eg_id)
      InsurancePolicies::AcaIndividuals::InsurancePolicy.where(:policy_id.in => glue_policy_ids)
    end

    def fetch_contract_holders(insurance_policies)
      insurance_policy_ids = insurance_policies.pluck(:policy_id)
      contract_holder_ids = contract_holder_ids_query(insurance_policy_ids)
      Success(contract_holder_ids)
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

    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/MethodLength
    def fetch_cv3_family(contract_holder_ids, params)
      logger = Logger.new("#{Rails.root}/log/enroll_refresh_#{Date.today.strftime('%Y_%m_%d')}.log")
      total_people_count = contract_holder_ids.count
      counter = 0
      logger.info("Operation started at #{DateTime.now} ")
      contract_holder_ids.no_timeout.each do |id|
        person = People::Person.find(id)
        event = event("events.families.cv3_family.requested", attributes: { person_hbx_id: person.hbx_id,
                                                                            year: params[:start_date].year })
        event.success.publish
        counter += 1
        logger.info("published #{counter} out of #{total_people_count}") if (counter % 100).zero?
      rescue StandardError => e
        logger.info("unable to publish member with id #{id} due to #{e.inspect}")
      end
      logger.info("Operation ended at #{DateTime.now} ")
      Success("requested cv3 family for all people")
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength
  end
end
