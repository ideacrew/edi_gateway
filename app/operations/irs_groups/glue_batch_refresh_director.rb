# frozen_string_literal: true

module IrsGroups
  # Refresh EDI gateway database with policy information
  class GlueBatchRefreshDirector
    include Dry::Monads[:result, :do, :try]

    def call(params)
      values = yield validate(params)
      result = yield publish_policies_refresh(values)

      Success(result)
    end

    private

    def validate(params)
      errors = []
      errors << "policies required and must be an array" unless params[:policies].is_a?(Array)
      errors << "policies_to_exclude required and must be an hash" unless params[:policies_to_exclude].is_a?(Hash)

      errors.empty? ? Success(params) : Failure(errors)
    end

    # rubocop:disable Metrics/AbcSize
    def publish_policies_refresh(values)
      logger = Logger.new("#{Rails.root}/log/glue_batch_refresh_director_#{Date.today.strftime('%Y_%m_%d')}.log")
      counter = 0
      logger.info("Operation started at #{DateTime.now} ")
      values[:policies].each do |policy_id|
        if values[:policies_to_exclude].has_key?(policy_id)
          logger.info("skipped #{policy_id} since its in the exclusion list")
          next
        end
        GluePolicyRefreshDirector.new.call({ policy_id: policy_id })
        counter += 1
        logger.info("published #{counter} out of #{values[:policies].count}") if (counter % 100).zero?
      end
      logger.info("Operation ended at #{DateTime.now} ")
      Success("published all policies")
    end
    # rubocop:enable Metrics/AbcSize
  end
end

