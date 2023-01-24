# frozen_string_literal: true

module IrsGroups
  # Refresh EDI gateway database with cv3 family information
  class EnrollBatchRefreshDirector
    include Dry::Monads[:result, :do, :try]
    include EventSource::Command

    def call(params)
      values = yield validate(params)
      result = yield publish_families_refresh(values)

      Success(result)
    end

    private

    def validate(params)
      errors = []
      errors << "calendar_year required" unless params[:calendar_year]
      errors << "people required and must be an array" unless params[:people].is_a?(Array)
      errors << "people_to_exclude required and must be an hash" unless params[:people_to_exclude].is_a?(Hash)

      errors.empty? ? Success(params) : Failure(errors)
    end

    # rubocop:disable Metrics/AbcSize
    def publish_families_refresh(values)
      logger = Logger.new("#{Rails.root}/log/enroll_batch_refresh_director_#{Date.today.strftime('%Y_%m_%d')}.log")
      counter = 0
      logger.info("Operation started at #{DateTime.now} ")
      values[:people].each do |person_hbx_id|
        if values[:people_to_exclude].key?(person_hbx_id)
          logger.info("skipped #{person_hbx_id} since its in the exclusion list")
          next
        end
        EnrollFamilyRefreshDirector.new.call({ primary_hbx_id: person_hbx_id, calendar_year: values[:calendar_year] })
        counter += 1
        logger.info("published #{counter} out of #{values[:people].count}") if (counter % 100).zero?
      end
      logger.info("Operation ended at #{DateTime.now} ")
      Success("published all people")
    end
  end
end
