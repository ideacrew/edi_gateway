# frozen_string_literal: true

module Reports
  # request glue to get coverage history for subscriber
  class RequestCoverageHistoryForSubscriber
    send(:include, Dry::Monads[:result, :do])
    send(:include, Dry::Monads[:try])

    def call(params)
      valid_params = yield validate(params)
      @logger = valid_params[:logger]
      coverage_history_response = yield fetch_coverage_history(valid_params)
      status = yield store_coverage_history(coverage_history_response, valid_params[:audit_report_datum])
      Success(status)
    end

    private

    def validate(params)
      return Failure("No audit datum record") if params[:audit_report_datum].blank?

      Success(params)
    end

    def read_show_filter(params)
      filter_parameters = Hash.new
      year_param = params[:year]
      hios_param = params[:hios_id]
      filter_parameters[:year] = year_param.to_i unless year_param.blank?
      filter_parameters[:hios_id] = hios_param unless hios_param.blank?
      filter_parameters
    end

    def fetch_coverage_history(valid_params)
      audit_datum = valid_params[:audit_report_datum]
      hios_id = valid_params[:audit_report_datum].hios_id
      params = { year: audit_datum.year, hios_id: hios_id }
      member_id = audit_datum.subscriber_id

      begin
        person = Person.find_for_member_id(member_id)
        response = SubscriberInventory.coverage_inventory_for(person, read_show_filter(params))
        @logger.info "Response from glue for subscriber #{audit_datum.subscriber_id} payload #{response}" if @logger.present?
        Success(response)
      rescue StandardError => e
        Rails.logger.error e.message
        Failure("Unable to fetch coverage history due to #{e.message}")
      end
    end

    def store_coverage_history(coverage_history_response, audit_datum)
      status = audit_datum.update_attributes(payload: coverage_history_response, status: "completed")
      policies_response = coverage_history_response
      policies_response.each do |policy|
        audit_datum.ard_policies << ArdPolicy.new(payload: policy.to_json, policy_eg_id: policy["enrollment_group_id"])
      end
      if @logger.present?
        @logger.info "audit status in our db for subscriber #{audit_datum.subscriber_id} - #{audit_datum.status}"
      end
      Success(status)
    end
  end
end
