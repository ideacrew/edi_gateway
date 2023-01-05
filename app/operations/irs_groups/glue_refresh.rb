# frozen_string_literal: true

module IrsGroups
  # Refresh EDI gateway database with policy information
  class GlueRefresh
    include Dry::Monads[:result, :do, :try]
    include EventSource::Command
    require 'dry/monads'
    require 'dry/monads/do'

    def call(params)
      validated_params = yield validate(params)
      policies = yield fetch_glue_policies_for_year(validated_params)
      result = yield persist(policies)
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
                                                                                  :'$lt' => params[:end_date] } } }).limit(100))
    end

    # rubocop:disable Metrics/AbcSize
    def persist(policies)
      logger = Logger.new("#{Rails.root}/log/glue_refresh_#{Date.today.strftime('%Y_%m_%d')}.log")
      total_policies_count = policies.count
      counter = 0

      logger.info("Operation started at #{DateTime.now} ")
      policies.no_timeout.each do |policy|
        event = event("events.edi_database.irs_groups.policy_and_insurance_agreement_created",
                      attributes: { policy_id: policy.id })
        event.success.publish
        counter += 1
        logger.info("published #{counter} out of #{total_policies_count}") if (counter % 100).zero?
      rescue StandardError => e
        logger.info("unable to publish policy with policy_id #{policy.id} due to #{e.inspect}")
      end
      logger.info("Operation ended at #{DateTime.now} ")
      Success("published all policies")
    end
    # rubocop:enable Metrics/AbcSize
  end
end
