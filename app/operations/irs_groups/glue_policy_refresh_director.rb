# frozen_string_literal: true

module IrsGroups
  # Refresh EDI gateway database with policy information from glue
  class GluePolicyRefreshDirector
    include Dry::Monads[:result, :do, :try]
    include EventSource::Command

    def call(params)
      values = yield validate(params)
      result = yield refresh_policy(values)

      Success(result)
    end

    private

    def validate(params)
      errors = []
      errors << "policy_id is required" unless params[:policy_id]

      errors.empty? ? Success(params) : Failure(errors)
    end

    # rubocop:disable Metrics/AbcSize
    def refresh_policy(values)
      logger = Logger.new("#{Rails.root}/log/glue_policy_refresh_director_#{Date.today.strftime('%Y_%m_%d')}.log")
      event = event("events.edi_database.irs_groups.policy_and_insurance_agreement_created",
                    attributes: { policy_id: values[:policy_id] })
      event.success.publish
      logger.info("published policy refresh event for #{values[:policy_id]} at #{DateTime.now}")

      Success("published policy refresh event for #{values[:policy_id]} at #{DateTime.now}")
    rescue StandardError => e
      logger.info("unable to publish policy with policy_id #{values[:policy_id]} due to #{e.inspect}")
      Failure("unable to publish policy with policy_id #{values[:policy_id]} due to #{e.inspect}")
    end
    # rubocop:enable Metrics/AbcSize
  end
end
