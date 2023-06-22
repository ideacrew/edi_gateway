# frozen_string_literal: true

require 'csv'

module Reports
  # Store coverage history for a subscriber and publish event to generate report
  class GeneratePreAuditReport
    send(:include, Dry::Monads[:result, :do])
    send(:include, Dry::Monads[:try])

    def call(params)
      valid_params = yield validate(params)
      audit_datum = yield fetch_audit_report_datum(valid_params)
      carrier_hios_id = valid_params[:payload][:carrier_hios_id]
      year = valid_params[:payload][:year]
      @logger = Logger.new("#{Rails.root}/log/pre_audit_report_errors_#{carrier_hios_id}_#{year}")
      generate_report(carrier_hios_id, audit_datum, year)
      Success(true)
    end

    private

    def validate(params)
      parsed_params = JSON.parse(params[:payload]).deep_symbolize_keys!
      return Failure("No carrier hios id present") if parsed_params[:payload][:carrier_hios_id].blank?
      return Failure("Please pass in year") if parsed_params[:payload][:year].blank?

      Success(parsed_params)
    end

    def fetch_audit_report_datum(valid_params)
      audit_report_datum = AuditReportDatum.where(hios_id: valid_params[:payload][:carrier_hios_id],
                                                  year: valid_params[:payload][:year],
                                                  status: "completed",
                                                  report_type: "pre_audit")
      Success(audit_report_datum)
    end

    # rubocop:disable Metrics/AbcSize
    def generate_report(carrier_hios_id, audit_datum, year)
      file_name = fetch_file_name(carrier_hios_id, year)

      CSV.open(file_name, "w", col_sep: "|") do |csv|
        audit_datum.where(status: "completed").each do |audit_data|
          policies = JSON.parse(audit_data.payload)
          policies.each do |policy|
            policy_contract_result = AcaEntities::Contracts::Policies::PolicyContract.new.call(policy)
            if policy_contract_result.errors.present?
              @logger.error("policy_id: #{policy['policy_id']},
                            enrollment_group_id: #{policy['enrollment_group_id']},
                            validations errors from AcaEntities: #{policy_contract_result.errors.messages} \n")
            end

            policy_entity = AcaEntities::Policies::Policy.new(policy_contract_result.to_h)
            next unless policy_entity.exchange_subscriber_id == audit_data.subscriber_id

            policy_entity.enrollees.each do |enrollee|
              enrollee.segments.each do |segment|
                csv << insert_data(carrier_hios_id, policy_entity, segment, enrollee, audit_data)
              end
            end
          end
        rescue StandardError => e
          Rails.logger.error("Unable to generate report due to #{e}, #{e.backtrace.join("\n")}")
          @logger.error("Unable to generate report due to #{e}")
        end
      end
    end
    # rubocop:enable Metrics/AbcSize

    def fetch_relationship_code(code)
      {
        "self" => "1:18",
        "spouse" => "2:01",
        "ward" => "32:15",
        "child" => "4:19",
        "life partner" => "8:53"
      }.stringify_keys[code.to_s]
    end

    def aptc_amount(enrollee, segment)
      return nil unless enrollee.is_subscriber
      return nil if [0.0, 0, 0.00].include?(segment.aptc_amount)

      format('%.2f', segment.aptc_amount)
    end

    def effective_start_date(enrollee, segment)
      return nil unless enrollee.is_subscriber

      segment.effective_start_date&.strftime("%Y%m%d")
    end

    def effective_end_date(enrollee, segment)
      return nil unless enrollee.is_subscriber

      segment.effective_end_date&.strftime("%Y%m%d")
    end

    def csr_variant(enrollee, segment)
      return nil unless enrollee.is_subscriber

      segment.csr_variant
    end

    def total_premium_amount(enrollee, segment, policy_entity)
      return nil unless enrollee.is_subscriber

      if policy_entity.coverage_kind == "dental"
        format('%.2f', policy_entity.total_premium_amount)
      else
        format('%.2f', segment.total_premium_amount)
      end
    end

    def total_responsible_amount(enrollee, segment, policy_entity)
      return nil unless enrollee.is_subscriber

      if policy_entity.coverage_kind == "dental"
        format('%.2f', policy_entity.total_responsible_amount)
      else
        format('%.2f', segment.total_responsible_amount)
      end
    end

    def phone_number(enrollee)
      return nil if enrollee.phones.blank?

      enrollee.phones.last&.full_phone_number&.to_s&.rjust(10, "0")
    end

    def email_address(enrollee)
      return nil if enrollee.emails.blank?

      enrollee.emails.last.address
    end

    def transaction_code_type(enrollee)
      if enrollee&.coverage_start == enrollee&.coverage_end
        3
      else
        1
      end
    end

    def tobacco_use_code(enrollee)
      enrollee_age = age_of(enrollee)
      return 2 if enrollee_age < 18

      case enrollee.enrollee_demographics.tobacco_use_code
      when "Y"
        1
      when "N"
        2
      end
    end

    def age_of(enrollee)
      date = enrollee.coverage_start
      dob = enrollee.enrollee_demographics&.dob
      age = date.year - dob.year
      if date.month < dob.month || (date.month == dob.month && date.day < dob.day)
        age - 1
      else
        age
      end
    end

    def non_subscriber_end_date(enrollee, segment)
      return enrollee.coverage_end&.strftime("%Y%m%d") if enrollee.coverage_start == enrollee.coverage_end

      segment.effective_end_date&.strftime("%Y%m%d")
    end

    def qhp_id(policy_entity)
      "#{policy_entity.qhp_id}#{policy_entity.csr_variant}".first(16)
    end

    def gender_code(enrollee)
      gc = enrollee.enrollee_demographics.gender_code
      gc == "M" ? "Male" : "Female"
    end

    def fetch_file_name(carrier_hios_id, year)
      current_time = Time.now
      formatted_string = current_time.strftime("%Y%m%d%H%M%S")
      last_digit = year % 10
      "#{Rails.root}/AUD#{last_digit}_#{formatted_string}000Z_#{carrier_hios_id}_I"
    end

    def segment_id(id, policy_entity)
      result = id.split("-")
      result.delete_at(1)
      result.insert(1, policy_entity.enrollment_group_id)
      result.join("-")
    end

    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/PerceivedComplexity
    # rubocop:disable Metrics/MethodLength

    def insert_data(carrier_hios_id, policy_entity, segment, enrollee, audit_data)
      [carrier_hios_id, nil, "ME0", carrier_hios_id, policy_entity.qhp_id[0, 10],
       audit_data.created_at.strftime("%Y%m%d"), audit_data.created_at.strftime("%H%M%S%L"),
       policy_entity.last_maintenance_date.strftime("%Y%m%d"), policy_entity.last_maintenance_time,
       policy_entity.primary_subscriber&.hbx_member_id, transaction_code_type(enrollee), nil, nil,
       nil, nil, nil,
       fetch_relationship_code(enrollee.relationship_status_code), enrollee.is_subscriber ? 'Y' : 'N', nil,
       policy_entity.primary_subscriber&.hbx_member_id,
       enrollee.hbx_member_id, enrollee.issuer_assigned_member_id,
       policy_entity.primary_subscriber&.issuer_assigned_member_id, enrollee.last_name, enrollee.first_name,
       enrollee.middle_name, nil, enrollee.residential_address&.address_1, enrollee.residential_address&.address_2,
       enrollee.residential_address&.city, enrollee.residential_address&.state,
       enrollee.residential_address&.zip&.to_s&.rjust(5, "0"),
       enrollee.residential_address&.location_county_code, phone_number(enrollee),
       enrollee.enrollee_demographics&.ssn&.to_s&.rjust(9, "0"),
       enrollee.enrollee_demographics&.dob&.strftime("%Y%m%d"), gender_code(enrollee),
       tobacco_use_code(enrollee), nil, nil, nil, nil, email_address(enrollee),
       enrollee.mailing_address&.address_1,
       enrollee.mailing_address&.address_2, enrollee.mailing_address&.city, enrollee.mailing_address&.state,
       enrollee.mailing_address&.zip&.to_s&.rjust(5, "0"), nil, nil, nil, nil, nil, nil, nil,
       policy_entity.responsible_party_subscriber&.last_name, policy_entity.responsible_party_subscriber&.first_name,
       policy_entity.responsible_party_subscriber&.mailing_address&.address_1,
       policy_entity.responsible_party_subscriber&.mailing_address&.address_2,
       policy_entity.responsible_party_subscriber&.mailing_address&.city,
       policy_entity.responsible_party_subscriber&.mailing_address&.state,
       policy_entity.responsible_party_subscriber&.mailing_address&.zip&.to_s&.rjust(5, "0"),
       segment.effective_start_date&.strftime("%Y%m%d"), non_subscriber_end_date(enrollee, segment),
       enrollee.issuer_assigned_policy_id, qhp_id(policy_entity), policy_entity.effectuation_status,
       policy_entity.enrollment_group_id, segment_id(segment.id, policy_entity), aptc_amount(enrollee, segment),
       effective_start_date(enrollee, segment), effective_end_date(enrollee, segment),
       nil, effective_start_date(enrollee, segment),
       effective_end_date(enrollee, segment), total_premium_amount(enrollee, segment, policy_entity),
       effective_start_date(enrollee, segment), effective_end_date(enrollee, segment),
       format('%.2f', segment.individual_premium_amount),
       segment.effective_start_date&.strftime("%Y%m%d"), non_subscriber_end_date(enrollee, segment),
       total_responsible_amount(enrollee, segment, policy_entity), segment.effective_start_date&.strftime("%Y%m%d"),
       segment.effective_end_date&.strftime("%Y%m%d"), nil, nil, nil, policy_entity.term_for_np ? 6 : nil, nil,
       policy_entity.term_for_np ? 6 : nil,
       policy_entity.rating_area, nil, nil, nil, policy_entity.insurance_line_code, nil, nil, nil, nil, nil, nil, nil,
       nil, nil]
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/PerceivedComplexity
    # rubocop:enable Metrics/MethodLength
  end
end
