# frozen_string_literal: true

module IrsGroups
  # Refresh EDI gateway database with family cv3 payload from enroll
  class EnrollFamilyRefreshDirector
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
      errors << "primary_hbx_id is required" unless params[:primary_hbx_id]
      errors << "calendar_year is required" unless params[:calendar_year]

      errors.empty? ? Success(params) : Failure(errors)
    end

    def refresh_policy(values)
      logger = Logger.new("#{Rails.root}/log/enroll_family_refresh_director_#{Date.today.strftime('%Y_%m_%d')}.log")
      event = event("events.families.cv3_family.requested", attributes: { person_hbx_id: values[:primary_hbx_id],
                                                                          year: values[:calendar_year] })
      event.success.publish
      logger.info("published family refresh event for #{values[:primary_hbx_id]} at #{DateTime.now}")
      Success("published family refresh event for #{values[:primary_hbx_id]} at #{DateTime.now}")
    rescue StandardError => e
      logger.info("unable to publish family refresh for #{values[:primary_hbx_id]} due to #{e.inspect}")
      Failure("unable to publish family refresh for #{values[:primary_hbx_id]} due to #{e.inspect}")
    end
  end
end

