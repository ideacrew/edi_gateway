# frozen_string_literal: true

require 'csv'

module Reports
  # Store coverage history for a subscriber and publish event to generate report
  # rubocop:disable Metrics/ClassLength
  class GenerateRcnoReport
    include Dry::Monads[:result, :do]

    def call(params)
      valid_params = yield validate(params)
      audit_datum = yield fetch_audit_report_datum(valid_params)
      carrier_hios_id = valid_params[:payload][:carrier_hios_id]
      year = valid_params[:payload][:year]
      @logger = Logger.new("#{Rails.root}/log/rcno_report_errors_#{carrier_hios_id}_#{year}")
      rcni_file_path = yield fetch_rcni_file_path(carrier_hios_id)
      generate_rcno_report(rcni_file_path, valid_params, audit_datum)
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
      report_type = AuditReportDatum.where(report_type: "rcno").present? ? "rcno" : "pre_audit"
      audit_report_datum = AuditReportDatum.where(hios_id: valid_params[:payload][:carrier_hios_id],
                                                  year: valid_params[:payload][:year],
                                                  status: "completed",
                                                  report_type: report_type)
      Success(audit_report_datum)
    end

    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/CyclomaticComplexity
    def generate_rcno_report(rcni_file_path, valid_params, audit_datum)
      file_name = fetch_rcno_file_name(valid_params)
      @total_number_of_issuer_records = 0
      @total_subscribers = 0
      @total_dependents = 0
      @total_premium_amount = 0.00
      @total_applied_premium_amount = 0.00
      CSV.open(file_name, "w", col_sep: "|") do |csv|
        File.readlines(rcni_file_path, chomp: true).each do |line|
          @overall_flag = "M"
          @rcni_row = line.split("|")
          next unless @rcni_row[0] == "01"

          # mark over flag to U unprocessable if subscriber_id, member_id, policy_id, or benefit_start_date are blank?
          if @rcni_row[16].blank? || @rcni_row[17].blank? || @rcni_row[20].blank? || @rcni_row[37].blank?
            @overall_flag = "U"
          else
            @audit_record = audit_datum.where(subscriber_id: @rcni_row[16]).first
            if @audit_record.blank?
              # Create a row in RCNO with blank maine data and RCNI eched out carrier data
              # Every field level disposition should be D which is did not compare
              # Overall record level disposition should be R
              @overall_flag = "R"
              @logger.info "Unable to find subscriber from given rcni report #{@rcni_row[16]}"
            else
              @policy, @member, @segments = fetch_policy_member_and_segments
              segment = fetch_segment(@rcni_row[37])
              # If segment(RCNI benefit_start_date) is blank then set @overall_flag is 'B'.
              @overall_flag = "B" if segment.blank?
            end
          end
          csv << insert_data
          @total_number_of_issuer_records += 1
        rescue StandardError => e
          puts e
          puts "Error for row #{@rcni_row}"
          @logger.info "Unable to generate report due to #{e.backtrace} for member #{@member} record row #{@rcni_row}"
          Rails.logger.error("Unable to generate report due to #{e} for row #{@rcni_row}")
        end
        insert_missing_policy_data(csv, valid_params, rcni_file_path)
        csv << insert_total_record_data
      rescue StandardError => e
        puts e
        puts "Error for row #{@rcni_row}"
        @logger.info "Unable to generate report due to #{e.backtrace} for member #{@member} record row #{@rcni_row}"
        Rails.logger.error("Unable to generate report due to #{e} for row #{@rcni_row}")
      end
    end
    # rubocop:enable Metrics/MethodLength

    def fetch_policy_member_and_segments
      policies = @audit_record.ard_policies
      fetched_policy = policies.detect { |policy| (policy.policy_eg_id == @rcni_row[20]) }
      if fetched_policy.present?
        fetched_policies = policies.select { |policy| policy.policy_eg_id == @rcni_row[20] }
        fetched_policies.each { |pol| pol.update_attributes!(rcno_processed: true) }
      end
      if fetched_policy.blank?
        @overall_flag = "R"
        return [nil, nil, nil]
      end
      policy_contract_result = AcaEntities::Contracts::Policies::PolicyContract.new.call(JSON.parse(fetched_policy.payload))
      return [nil, nil, nil] if policy_contract_result.failure?

      policy_entity = AcaEntities::Policies::Policy.new(policy_contract_result.to_h)

      member = policy_entity.enrollees.detect { |enrollee| enrollee.hbx_member_id == @rcni_row[17] }
      if member.present?
        segments = member.segments
        @overall_flag = "R" if segments.blank?
      else
        @overall_flag = "R"
        segments = nil
      end
      [policy_entity, member, segments]
    end

    def fetch_rcni_file_path(hios_id)
      return Success("#{Rails.root}/spec/test_payloads/RCNI_33653.txt") if Rails.env.test?

      if File.exist?("#{Rails.root}/RCNI_#{hios_id}.txt")
        Success("#{Rails.root}/RCNI_#{hios_id}.txt")
      else
        Failure("Unable to find rcni file for hios id #{hios_id}")
      end
    end

    def fetch_rcno_file_name(valid_params)
      hios_id = valid_params[:payload][:carrier_hios_id]
      year = valid_params[:payload][:year]
      current_time = Time.now
      formatted_string = current_time.strftime("%Y%m%d%H%M%S")
      last_digit = year % 10
      "#{Rails.root}/RCNO#{last_digit}_#{formatted_string}000Z_#{hios_id}_I"
    end

    def fetch_relationship_code(code)
      {
        "self" => "18",
        "spouse" => "01",
        "ward" => "15",
        "child" => "19",
        "life partner" => "53"
      }.stringify_keys[code.to_s]
    end

    def fetch_segment(coverage_start)
      return if coverage_start.blank?
      return if @segments.blank?

      # unprocessed policy
      start = if @overall_flag == "G"
                coverage_start
              else
                Date.strptime(coverage_start, "%Y%m%d")
              end
      @segments.detect { |segment| segment.effective_start_date == start }
    end

    def phone_number
      return nil if @member.blank?
      return nil if @member&.phones&.blank?

      @member.phones.last.full_phone_number&.gsub("|", "")
    end

    def tobacco_use_code(tobacco_code)
      case tobacco_code
      when "Y"
        1
      when "N"
        2
      end
    end

    def qhp_id(issuer_qhp_id)
      if issuer_qhp_id.length == 14
        @policy.qhp_id.to_s
      else
        "#{@policy.qhp_id}#{@policy.csr_variant}"
      end
    end

    def fetch_applied_aptc_amount(segment)
      return 0.00 unless @member.is_subscriber
      return 0.00 if [0.0, 0, 0.00].include?(@policy.applied_aptc) && segment.blank?

      segment.present? ? segment.aptc_amount : @policy.applied_aptc
    end

    def fetch_effectuation_status
      if @policy.effectuation_status == "N" && @policy.aasm_state == "canceled"
        "C"
      elsif @policy.effectuation_status == "Y" || @member.issuer_assigned_policy_id.present?
        "Y"
      else
        @policy.effectuation_status
      end
    end

    def members_count(status)
      if status == "Y"
        @total_subscribers += 1
      else
        @total_dependents += 1
      end
    end

    def compare_first_name
      # If overall flag is R then we need to put ME data blank, carrier data from RCNI, and field level disposition to D
      # If overall flag is not a R then we do normal data population for ME and carrier and field level disposition
      # If Subscriber, Member, or Policy are not found
      return [nil, @rcni_row[8], "D"] if @overall_flag == "R" || @overall_flag == "U" || @overall_flag == "B"

      # return [nil, @rcni_row[8], "U"] if @member.blank?
      ffm_first_name = @member.first_name&.gsub("|", "")

      # unprocessed policy
      return [ffm_first_name, nil, "D"] if @overall_flag == "G"

      issuer_first_name = @rcni_row[8]
      match_data = /#{ffm_first_name}/i.match?(issuer_first_name) ? "M" : "I"
      @overall_flag = "N" if match_data == "I"
      [ffm_first_name, issuer_first_name, match_data]
    end

    def compare_middle_name
      # If Subscriber, Member, or Policy are not found
      return [nil, @rcni_row[9], "D"] if @overall_flag == "R" || @overall_flag == "U" || @overall_flag == "B"

      # return [nil, @rcni_row[9], "U"] if @member.blank?

      ffm_middle_name = @member.middle_name&.gsub("|", "")

      # unprocessed policy
      return [ffm_middle_name, nil, "D"] if @overall_flag == "G"

      issuer_middle_name = @rcni_row[9]
      return [ffm_middle_name, issuer_middle_name, "D"] if ffm_middle_name.blank? && issuer_middle_name.blank?

      match_data = "D"
      [ffm_middle_name, issuer_middle_name, match_data]
    end

    def compare_last_name
      # If Subscriber, Member, or Policy are not found
      return [nil, @rcni_row[10], "D"] if @overall_flag == "R" || @overall_flag == "U" || @overall_flag == "B"

      # return [nil, @rcni_row[10], "U"] if @member.blank?

      ffm_last_name = @member.last_name&.gsub("|", "")

      # unprocessed policy
      return [ffm_last_name, nil, "D"] if @overall_flag == "G"

      issuer_last_name = @rcni_row[10]
      match_data = /#{ffm_last_name}/i.match?(issuer_last_name) ? "M" : "I"
      @overall_flag = "N" if match_data == "I"
      [ffm_last_name, issuer_last_name, match_data]
    end

    def compare_dob
      # If Subscriber, Member, or Policy are not found
      return [nil, @rcni_row[11], "D"] if @overall_flag == "R" || @overall_flag == "U" || @overall_flag == "B"

      # return [nil, @rcni_row[11], "U"] if @member.blank?

      ffm_dob = @member.enrollee_demographics.dob.strftime("%Y%m%d")

      # unprocessed policy
      return [ffm_dob, nil, "D"] if @overall_flag == "G"

      issuer_dob = @rcni_row[11]
      match_data = ffm_dob == issuer_dob ? "M" : "I"
      @overall_flag = "N" if match_data == "I"
      [ffm_dob, issuer_dob, match_data]
    end

    def compare_gender
      # If Subscriber, Member, or Policy are not found
      return [nil, @rcni_row[12], "D"] if @overall_flag == "R" || @overall_flag == "U" || @overall_flag == "B"

      # return [nil, @rcni_row[12], "U"] if @member.blank?

      ffm_gender = @member.enrollee_demographics.gender_code

      # unprocessed policy
      return [ffm_gender, nil, "D"] if @overall_flag == "G"

      issuer_gender = @rcni_row[12]
      [ffm_gender, issuer_gender, "D"]
    end

    def compare_ssn
      # If Subscriber, Member, or Policy are not found
      return [nil, @rcni_row[13], "D"] if @overall_flag == "R" || @overall_flag == "U" || @overall_flag == "B"

      # return [nil, @rcni_row[13], "U"] if @member.blank?

      ffm_ssn = @member.enrollee_demographics.ssn

      # unprocessed policy
      return [ffm_ssn, nil, "D"] if @overall_flag == "G"

      issuer_ssn = @rcni_row[13]
      [ffm_ssn, issuer_ssn, "D"]
    end

    def subscriber_indicator
      # If Subscriber, Member, or Policy are not found
      return [nil, @rcni_row[14], "D"] if @overall_flag == "R" || @overall_flag == "U" || @overall_flag == "B"

      status = @member&.is_subscriber ? 'Y' : 'N'
      members_count(status)
      # return [nil, @rcni_row[14], "U"] if @member.blank?

      ffm_subscriber_status = status

      # unprocessed policy
      return [ffm_subscriber_status, nil, "D"] if @overall_flag == "G"

      issuer_subscriber_status = @rcni_row[14]
      match_data = /#{ffm_subscriber_status}/i.match?(issuer_subscriber_status) ? "M" : "I"
      @overall_flag = "N" if match_data == "I"
      [ffm_subscriber_status, issuer_subscriber_status, match_data]
    end

    def relation_to_subscriber_indicator
      # If Subscriber, Member, or Policy are not found
      return [nil, @rcni_row[15], "D"] if @overall_flag == "R" || @overall_flag == "U" || @overall_flag == "B"

      # return [nil, @rcni_row[15], "U"] if @member.blank?

      ffm_subscriber_status = fetch_relationship_code(@member.relationship_status_code)

      # unprocessed policy
      return [ffm_subscriber_status, nil, "D"] if @overall_flag == "G"

      issuer_subscriber_status = @rcni_row[15]
      [ffm_subscriber_status, issuer_subscriber_status, "D"]
    end

    def exchange_assigned_subscriber_id
      return [nil, @rcni_row[16], "U"] if @rcni_row[16].blank? && @overall_flag == "U"
      # If Subscriber, Member, or Policy are not found
      return [nil, @rcni_row[16], "D"] if @overall_flag == "R"

      ffm_subscriber_id = @policy.primary_subscriber&.hbx_member_id

      # If Subscriber, Member and Policy are found but no segment, echo match for subscriberID
      return [ffm_subscriber_id, @rcni_row[16], "M"] if @overall_flag == "B"

      # unprocessed policy
      return [ffm_subscriber_id, nil, "D"] if @overall_flag == "G"

      issuer_subscriber_id = @rcni_row[16]
      match_data = ffm_subscriber_id == issuer_subscriber_id ? "M" : "I"
      [ffm_subscriber_id, issuer_subscriber_id, match_data]
    end

    def exchange_assigned_member_id
      return [nil, @rcni_row[17], "U"] if @rcni_row[17].blank? && @overall_flag == "U"
      # If Subscriber, Member, or Policy are not found
      return [nil, @rcni_row[17], "D"] if @overall_flag == "R"

      # return [nil, @rcni_row[17], "U"] if @member.blank?
      ffm_member_id = @member.hbx_member_id

      # If Subscriber, Member and Policy are found but no segment, echo match for member_id
      return [ffm_member_id, @rcni_row[17], "M"] if @overall_flag == "B"

      # unprocessed policy
      return [ffm_member_id, nil, "D"] if @overall_flag == "G"

      issuer_member_id = @rcni_row[17]
      match_data = ffm_member_id == issuer_member_id ? "M" : "I"
      [ffm_member_id, issuer_member_id, match_data]
    end

    def issuer_assigned_subscriber_id
      # If Subscriber, Member, or Policy are not found
      return [nil, @rcni_row[18], "D"] if @overall_flag == "R" || @overall_flag == "U" || @overall_flag == "B"

      # return [nil, @rcni_row[18], "U"] if @policy.blank?

      ffm_issuer_subscriber_id = @policy.primary_subscriber&.issuer_assigned_member_id

      # unprocessed policy
      return [ffm_issuer_subscriber_id, nil, "D"] if @overall_flag == "G"

      issuer_issuer_subscriber_id = @rcni_row[18]

      if ffm_issuer_subscriber_id.blank? && issuer_issuer_subscriber_id.blank?
        return [ffm_issuer_subscriber_id, issuer_issuer_subscriber_id,
                "D"]
      end
      if ffm_issuer_subscriber_id.blank? && issuer_issuer_subscriber_id.present?
        return [ffm_issuer_subscriber_id, issuer_issuer_subscriber_id,
                "F"]
      end
      if ffm_issuer_subscriber_id.present? && issuer_issuer_subscriber_id.blank?
        return [ffm_issuer_subscriber_id, issuer_issuer_subscriber_id,
                "K"]
      end

      match_data = ffm_issuer_subscriber_id == issuer_issuer_subscriber_id ? "M" : "G"
      [ffm_issuer_subscriber_id, issuer_issuer_subscriber_id, match_data]
    end

    def issuer_assigned_member_id
      # If Subscriber, Member, or Policy are not found
      return [nil, @rcni_row[19], "D"] if @overall_flag == "R" || @overall_flag == "U" || @overall_flag == "B"

      # return [nil, @rcni_row[19], "U"] if @member.blank?

      ffm_issuer_member_id = @member.issuer_assigned_member_id

      # unprocessed policy
      return [ffm_issuer_member_id, nil, "D"] if @overall_flag == "G"

      issuer_issuer_member_id = @rcni_row[19]

      return [ffm_issuer_member_id, issuer_issuer_member_id, "D"] if ffm_issuer_member_id.blank? && issuer_issuer_member_id.blank?

      if ffm_issuer_member_id.blank? && issuer_issuer_member_id.present?
        return [ffm_issuer_member_id, issuer_issuer_member_id,
                "F"]
      end
      if ffm_issuer_member_id.present? && issuer_issuer_member_id.blank?
        return [ffm_issuer_member_id, issuer_issuer_member_id,
                "K"]
      end

      match_data = ffm_issuer_member_id == issuer_issuer_member_id ? "M" : "G"
      [ffm_issuer_member_id, issuer_issuer_member_id, match_data]
    end

    def exchange_assigned_policy_number
      return [nil, @rcni_row[20], "U"] if @rcni_row[20].blank? && @overall_flag == "U"
      # If Subscriber, Member, or Policy are not found
      return [nil, @rcni_row[20], "D"] if @overall_flag == "R"

      # return [nil, @rcni_row[20], "U"] if @policy.blank?

      ffm_exchange_policy_number = @policy.enrollment_group_id

      # If Subscriber, Member and Policy are found but no segment, echo match for policy number
      return [ffm_exchange_policy_number, @rcni_row[20], "M"] if @overall_flag == "B"

      # unprocessed policy
      return [ffm_exchange_policy_number, nil, "D"] if @overall_flag == "G"

      issuer_exchange_policy_number = @rcni_row[20]
      match_data = ffm_exchange_policy_number == issuer_exchange_policy_number ? "M" : "I"
      @overall_flag = "N" if match_data == "I"
      [ffm_exchange_policy_number, issuer_exchange_policy_number, match_data]
    end

    def issuer_assigned_policy_number
      # If Subscriber, Member, or Policy are not found
      return [nil, @rcni_row[21], "D"] if @overall_flag == "R" || @overall_flag == "U" || @overall_flag == "B"

      # return [nil, @rcni_row[21], "U"] if @member.blank?

      ffm_issuer_policy_number = @member.issuer_assigned_policy_id

      # unprocessed policy
      return [ffm_issuer_policy_number, nil, "D"] if @overall_flag == "G"

      issuer_issuer_policy_number = @rcni_row[21]

      if ffm_issuer_policy_number.blank? && issuer_issuer_policy_number.blank?
        return [ffm_issuer_policy_number, issuer_issuer_policy_number,
                "D"]
      end
      if ffm_issuer_policy_number.blank? && issuer_issuer_policy_number.present?
        return [ffm_issuer_policy_number, issuer_issuer_policy_number,
                "F"]
      end
      if ffm_issuer_policy_number.present? && issuer_issuer_policy_number.blank?
        return [ffm_issuer_policy_number, issuer_issuer_policy_number,
                "K"]
      end

      match_data = ffm_issuer_policy_number == issuer_issuer_policy_number ? "M" : "G"
      [ffm_issuer_policy_number, issuer_issuer_policy_number, match_data]
    end

    def residential_address_state
      # If Subscriber, Member, or Policy are not found
      return [nil, @rcni_row[25], "D"] if @overall_flag == "R" || @overall_flag == "U"

      # return [nil, @rcni_row[25], "U"] if @member.blank?

      ffm_residential_address_state = @member&.residential_address&.state&.gsub("|", "")

      # unprocessed policy
      return [ffm_residential_address_state, nil, "D"] if @overall_flag == "G"

      issuer_residential_address_state = @rcni_row[25]
      match_data = ffm_residential_address_state == issuer_residential_address_state ? "M" : "I"
      @overall_flag = "N" if match_data == "I"
      [ffm_residential_address_state, issuer_residential_address_state, match_data]
    end

    def residential_address_zip
      # If Subscriber, Member, or Policy are not found
      return [nil, @rcni_row[26]&.first(9), "D"] if @overall_flag == "R" || @overall_flag == "U"

      # return [nil, @rcni_row[26]&.first(9), "U"] if @member.blank?

      ffm_residential_address_zip = @member&.residential_address&.zip&.gsub("|", "")&.first(9)

      # unprocessed policy
      return [ffm_residential_address_zip, nil, "D"] if @overall_flag == "G"

      issuer_residential_address_zip = @rcni_row[26]&.first(9)
      match_data = ffm_residential_address_zip == issuer_residential_address_zip ? "M" : "I"
      @overall_flag = "N" if match_data == "I"
      [ffm_residential_address_zip, issuer_residential_address_zip, match_data]
    end

    def mailing_address_state
      # If Subscriber, Member, or Policy are not found
      return [nil, @rcni_row[30], "D"] if @overall_flag == "R" || @overall_flag == "U"

      # return [nil, @rcni_row[30], "U"] if @member.blank?

      ffm_mailing_address_state = @member&.mailing_address&.state&.gsub("|", "")

      # unprocessed policy
      return [ffm_mailing_address_state, nil, "D"] if @overall_flag == "G"

      issuer_mailing_address_state = @rcni_row[30]
      match_data = ffm_mailing_address_state == issuer_mailing_address_state ? "M" : "I"
      @overall_flag = "N" if match_data == "I"
      [ffm_mailing_address_state, issuer_mailing_address_state, match_data]
    end

    def mailing_address_zip
      # If Subscriber, Member, or Policy are not found
      return [nil, @rcni_row[31], "D"] if @overall_flag == "R" || @overall_flag == "U"

      # return [nil, @rcni_row[31], "U"] if @member.blank?

      ffm_mailing_address_zip = @member&.mailing_address&.zip&.gsub("|", "")

      # unprocessed policy
      return [ffm_mailing_address_zip, nil, "D"] if @overall_flag == "G"

      issuer_mailing_address_zip = @rcni_row[31]
      match_data = ffm_mailing_address_zip == issuer_mailing_address_zip ? "M" : "I"
      @overall_flag = "N" if match_data == "I"
      [ffm_mailing_address_zip, issuer_mailing_address_zip, match_data]
    end

    def residential_address_county
      # If Subscriber, Member, or Policy are not found
      return [nil, @rcni_row[32]&.first(5), "D"] if @overall_flag == "R" || @overall_flag == "U"

      # return [nil, @rcni_row[32]&.first(5), "U"] if @member.blank?

      ffm_residential_address_county = @member&.residential_address&.county&.gsub("|", "")&.first(5)

      # unprocessed policy
      return [ffm_residential_address_county, nil, "D"] if @overall_flag == "G"

      issuer_residential_address_county = @rcni_row[32]&.first(5)
      match_data = ffm_residential_address_county == issuer_residential_address_county ? "M" : "I"
      @overall_flag = "N" if match_data == "I"
      [ffm_residential_address_county, issuer_residential_address_county, match_data]
    end

    def rating_area
      # If Subscriber, Member, or Policy are not found
      return [nil, @rcni_row[33], "D"] if @overall_flag == "R" || @overall_flag == "U"

      # return [nil, @rcni_row[33], "U"] if @policy.blank?

      ffm_rating_area = @policy&.rating_area

      # unprocessed policy
      return [ffm_rating_area, nil, "D"] if @overall_flag == "G"

      issuer_rating_area = @rcni_row[33]
      match_data = ffm_rating_area == issuer_rating_area ? "M" : "I"
      @overall_flag = "N" if match_data == "I"
      [ffm_rating_area, issuer_rating_area, match_data]
    end

    def qhp_id_match
      # If Subscriber, Member, or Policy are not found
      return [nil, @rcni_row[36], "D"] if @overall_flag == "R" || @overall_flag == "U" || @overall_flag == "B"

      # return [nil, @rcni_row[36], "U"] if @policy.blank?
      # unprocessed policy
      if @overall_flag == "G"
        unprocessed_qhp_id = "#{@policy.qhp_id}#{@policy.csr_variant}"
        return [unprocessed_qhp_id, nil, "D"]
      end
      ffm_qhp_id = qhp_id(@rcni_row[36])
      issuer_qhp_id = @rcni_row[36]
      match_data = ffm_qhp_id == issuer_qhp_id ? "M" : "I"
      @overall_flag = "N" if match_data == "I"
      [ffm_qhp_id, issuer_qhp_id, match_data]
    end

    def benefit_start_date
      return [nil, @rcni_row[37], "U"] if @rcni_row[37].blank? && @overall_flag == "U"

      # If Subscriber, Member, or Policy are not found
      return [nil, @rcni_row[37], "D"] if @overall_flag == "R"

      # If Subscriber, Member and Policy are found but no segment for the start date
      return [nil, @rcni_row[37], "I"] if @overall_flag == "B"

      # return [nil, @rcni_row[37], "U"] if @member.blank?
      # unprocessed policy
      if @overall_flag == "G"
        policy_sub_member = @policy.enrollees.detect { |enrollee| enrollee.hbx_member_id == @policy.exchange_subscriber_id }
        unprocessed_start_date = policy_sub_member&.coverage_start&.strftime("%Y%m%d")
        return [unprocessed_start_date, nil, "D"]
      end
      segment = fetch_segment(@rcni_row[37])
      if segment.blank?
        @overall_flag = "R"
        return [nil, @rcni_row[37], "D"]
      end
      start_date = segment&.effective_start_date

      ffm_benefit_start = start_date&.strftime("%Y%m%d")
      issuer_benefit_start = @rcni_row[37]

      match_data = ffm_benefit_start == issuer_benefit_start ? "M" : "I"
      @overall_flag = "N" if match_data == "I"
      [ffm_benefit_start, issuer_benefit_start, match_data]
    end

    # rubocop:disable Metrics/PerceivedComplexity
    def benefit_end_date
      # If Subscriber, Member, or Policy are not found
      return [nil, @rcni_row[38], "D"] if @overall_flag == "R" || @overall_flag == "U" || @overall_flag == "B"

      # unprocessed policy
      if @overall_flag == "G"
        policy_sub_member = @policy.enrollees.detect { |enrollee| enrollee.hbx_member_id == @policy.exchange_subscriber_id }
        unprocessed_end_date = policy_sub_member&.coverage_end&.strftime("%Y%m%d")
        return [unprocessed_end_date, nil, "D"]
      end
      return [nil, @rcni_row[38], "U"] if @member.blank?

      segment = fetch_segment(@rcni_row[37])
      if segment.blank?
        @overall_flag = "N"
        return [nil, @rcni_row[38], "D"]
      end
      end_date = segment&.effective_end_date

      ffm_benefit_end = end_date&.strftime("%Y%m%d")
      issuer_benefit_end = @rcni_row[38]
      if ffm_benefit_end == Date.today.end_of_year.strftime("%Y%m%d") && issuer_benefit_end.blank?
        return [ffm_benefit_end, issuer_benefit_end,
                "M"]
      end

      if ffm_benefit_end != issuer_benefit_end
        @overall_flag = "N"
        fti_flag = @policy.term_for_np ? "K" : "I"
        return [ffm_benefit_end, issuer_benefit_end, fti_flag]
      end

      [ffm_benefit_end, issuer_benefit_end, "M"]
    end

    def applied_aptc_value
      # If Subscriber, Member, or Policy are not found
      return [nil, @rcni_row[39], "D"] if @overall_flag == "R" || @overall_flag == "U" || @overall_flag == "B"
      return [nil, @rcni_row[39], "U"] if @member.blank?
      return ["0.00", @rcni_row[39], "D"] unless @member.is_subscriber

      segment = fetch_segment(@rcni_row[37])
      # Do no compare aptc if policy is canceled
      return [segment.aptc_amount, @rcni_row[39], "D"] if @rcni_row[51] == "C" && @policy.aasm_state == "canceled"

      # unprocessed policy
      if @overall_flag == "G"
        segment = fetch_segment(@member.coverage_start)
        unprocessed_aptc_amount = format('%.2f', fetch_applied_aptc_amount(segment))
        return [unprocessed_aptc_amount, nil, "D"]
      end

      if segment.blank? && @policy.insurance_line_code == "HLT"
        @overall_flag = "N"
        return [nil, @rcni_row[39], "D"]
      end

      @total_applied_premium_amount += fetch_applied_aptc_amount(segment)
      ffm_applied_aptc_amount = format('%.2f', fetch_applied_aptc_amount(segment))
      issuer_applied_aptc_amount = if @rcni_row[39].blank?
                                     "0.00"
                                   else
                                     [".00", "0.0", "0.00", "0"].include?(@rcni_row[39]) ? "0.00" : @rcni_row[39]
                                   end
      match_data = ffm_applied_aptc_amount == issuer_applied_aptc_amount ? "M" : "I"
      @overall_flag = "N" if match_data == "I"
      [ffm_applied_aptc_amount, issuer_applied_aptc_amount, match_data]
    end

    def applied_aptc_start_date
      # If Subscriber, Member, or Policy are not found
      return [nil, @rcni_row[40], "D"] if @overall_flag == "R" || @overall_flag == "U" || @overall_flag == "B"
      return [nil, @rcni_row[40], "U"] if @member.blank?

      # unprocessed policy
      if @overall_flag == "G"
        segment = fetch_segment(@member.coverage_start)
        start_date = segment&.effective_start_date

        unprocessed_aptc_start_date = start_date&.strftime("%Y%m%d")
        return [unprocessed_aptc_start_date, nil, "D"]
      end
      return [nil, @rcni_row[40], "D"] if @rcni_row[40].blank?

      segment = fetch_segment(@rcni_row[37])
      if segment.blank? && @policy.insurance_line_code == "HLT"
        @overall_flag = "N"
        return [nil, @rcni_row[40], "D"]
      end
      start_date = segment&.effective_start_date

      ffm_applied_aptc_start_date = start_date&.strftime("%Y%m%d")
      issuer_applied_start_date = @rcni_row[40]
      return [nil, issuer_applied_start_date, "D"] unless @member.is_subscriber

      match_data = ffm_applied_aptc_start_date == issuer_applied_start_date ? "M" : "I"
      @overall_flag = "N" if match_data == "I"
      [ffm_applied_aptc_start_date, issuer_applied_start_date, match_data]
    end

    def applied_aptc_end_date
      # If Subscriber, Member, or Policy are not found
      return [nil, @rcni_row[41], "D"] if @overall_flag == "R" || @overall_flag == "U" || @overall_flag == "B"
      return [nil, @rcni_row[41], "U"] if @member.blank?

      # unprocessed policy
      if @overall_flag == "G"
        segment = fetch_segment(@member.coverage_start)
        end_date = segment&.effective_end_date

        unprocessed_aptc_end_date = end_date&.strftime("%Y%m%d")
        return [unprocessed_aptc_end_date, nil, "D"]
      end
      return [nil, @rcni_row[41], "D"] if @rcni_row[41].blank?

      segment = fetch_segment(@rcni_row[37])
      if segment.blank? && @policy.insurance_line_code == "HLT"
        @overall_flag = "N"
        return [nil, @rcni_row[41], "D"]
      end
      end_date = segment&.effective_end_date

      ffm_applied_aptc_end_date = end_date&.strftime("%Y%m%d")
      issuer_applied_end_date = @rcni_row[41]

      return [nil, issuer_applied_end_date, "D"] unless @member.is_subscriber

      if ffm_applied_aptc_end_date == Date.today.end_of_year.strftime("%Y%m%d") && issuer_applied_end_date.blank?
        return [ffm_applied_aptc_end_date, issuer_applied_end_date,
                "M"]
      end

      match_data = ffm_applied_aptc_end_date == issuer_applied_end_date ? "M" : "I"
      @overall_flag = "N" if match_data == "I"
      [ffm_applied_aptc_end_date, issuer_applied_end_date, match_data]
    end

    # rubocop:disable Metrics/MethodLength
    def total_premium_amount
      # If Subscriber, Member, or Policy are not found
      return [nil, @rcni_row[45], "D"] if @overall_flag == "R" || @overall_flag == "U" || @overall_flag == "B"
      # return [nil, @rcni_row[45], "U"] if @member.blank?
      return [nil, @rcni_row[45], "D"] unless @member.is_subscriber

      segment = fetch_segment(@rcni_row[37])
      segment_premium_amount = segment&.total_premium_amount
      return [segment_premium_amount, @rcni_row[45], "D"] if @rcni_row[51] == "C" && @policy.aasm_state == "canceled"

      # unprocessed policy
      if @overall_flag == "G"
        segment = fetch_segment(@member.coverage_start)
        unprocessed_total_premium = begin
          format('%.2f', segment&.total_premium_amount)
        rescue StandardError
          "0.00"
        end
        return [unprocessed_total_premium, nil, "D"]
      end
      if segment.blank?
        @overall_flag = "N"
        return [nil, @rcni_row[45], "D"]
      end
      premium_amount = segment&.total_premium_amount
      @total_premium_amount += premium_amount
      ffm_total_premium = begin
        format('%.2f', premium_amount)
      rescue StandardError
        "0.00"
      end
      issuer_total_premium = @rcni_row[45]
      match_data = ffm_total_premium == issuer_total_premium ? "M" : "I"
      @overall_flag = "N" if match_data == "I"
      [ffm_total_premium, issuer_total_premium, match_data]
    end

    def total_premium_start_date
      # If Subscriber, Member, or Policy are not found
      return [nil, @rcni_row[46], "D"] if @overall_flag == "R" || @overall_flag == "U" || @overall_flag == "B"
      return [nil, @rcni_row[46], "U"] if @member.blank?

      # unprocessed policy
      if @overall_flag == "G"
        segment = fetch_segment(@member.coverage_start)
        unprocessed_total_premium_start = segment&.effective_start_date&.strftime("%Y%m%d")
        return [unprocessed_total_premium_start, nil, "D"]
      end
      return [nil, @rcni_row[46], "D"] if @rcni_row[46].blank?
      return [nil, @rcni_row[46], "D"] unless @member.is_subscriber

      segment = fetch_segment(@rcni_row[37])

      ffm_total_premium_start = segment&.effective_start_date&.strftime("%Y%m%d")
      issuer_total_premium_start = @rcni_row[46]

      if ffm_total_premium_start.blank?
        @overall_flag = "N"
        return [nil, @rcni_row[46], "D"]
      end

      match_data = ffm_total_premium_start == issuer_total_premium_start ? "M" : "I"
      @overall_flag = "N" if match_data == "I"
      [ffm_total_premium_start, issuer_total_premium_start, match_data]
    end

    def total_premium_end_date
      # If Subscriber, Member, or Policy are not found
      return [nil, @rcni_row[47], "D"] if @overall_flag == "R" || @overall_flag == "U" || @overall_flag == "B"
      return [nil, @rcni_row[47], "U"] if @member.blank?

      # unprocessed policy
      if @overall_flag == "G"
        segment = fetch_segment(@member.coverage_start)
        unprocessed_total_premium_end = segment&.effective_end_date&.strftime("%Y%m%d")
        return [unprocessed_total_premium_end, nil, "D"]
      end
      return [nil, @rcni_row[47], "D"] if @rcni_row[47].blank?
      return [nil, @rcni_row[47], "D"] unless @member.is_subscriber

      segment = fetch_segment(@rcni_row[37])

      ffm_total_premium_end = segment&.effective_end_date&.strftime("%Y%m%d")

      if ffm_total_premium_end.blank?
        @overall_flag = "N"
        return [nil, @rcni_row[47], "D"]
      end

      issuer_total_premium_end = @rcni_row[47]
      if ffm_total_premium_end == Date.today.end_of_year.strftime("%Y%m%d") && issuer_total_premium_end.blank?
        return [ffm_total_premium_end, issuer_total_premium_end,
                "M"]
      end

      match_data = ffm_total_premium_end == issuer_total_premium_end ? "M" : "I"
      @overall_flag = "N" if match_data == "I"
      [ffm_total_premium_end, issuer_total_premium_end, match_data]
    end

    def individual_premium_amount
      # If Subscriber, Member, or Policy are not found
      return [nil, @rcni_row[48], "D"] if @overall_flag == "R" || @overall_flag == "U" || @overall_flag == "B"

      # return [nil, @rcni_row[48], "U"] if @member.blank?

      # unprocessed policy
      if @overall_flag == "G"
        segment = fetch_segment(@member.coverage_start)
        amount = segment.present? ? segment.individual_premium_amount : 0.00
        premium_amount = @member.is_subscriber ? amount : @member.premium_amount
        unprocessed_individual_premium = format('%.2f', premium_amount)
        return [unprocessed_individual_premium, nil, "D"]
      end
      segment = fetch_segment(@rcni_row[37])
      issuer_premium_mount = @rcni_row[48]

      if segment.blank?
        @overall_flag = "N"
        return [nil, issuer_premium_mount, "D"]
      end

      amount = segment.present? ? segment.individual_premium_amount : 0.00

      premium_amount = @member.is_subscriber ? amount : @member.premium_amount

      ffm_individual_premium = format('%.2f', premium_amount)
      empty_premiums = %w[.00 0.0 0.00].include?(issuer_premium_mount) && ffm_individual_premium == "0.00"
      return [ffm_individual_premium, issuer_premium_mount, "D"] if empty_premiums
      return [ffm_individual_premium, issuer_premium_mount, "D"] if ["N", "C"].include?(@policy.effectuation_status)

      match_data = ffm_individual_premium == issuer_premium_mount ? "M" : "I"
      @overall_flag = "N" if match_data == "I"
      [ffm_individual_premium, issuer_premium_mount, match_data]
    end

    def individual_premium_start_date
      # If Subscriber, Member, or Policy are not found
      return [nil, @rcni_row[49], "D"] if @overall_flag == "R" || @overall_flag == "U" || @overall_flag == "B"

      # return [nil, @rcni_row[49], "U"] if @member.blank?

      # unprocessed policy
      if @overall_flag == "G"
        segment = fetch_segment(@member.coverage_start)
        start_date = segment&.effective_start_date
        unprocessed_individual_premium_start_date = start_date&.strftime("%Y%m%d")
        return [unprocessed_individual_premium_start_date, nil, "D"]
      end
      segment = fetch_segment(@rcni_row[37])
      start_date = segment&.effective_start_date

      ffm_ind_prem_start_date =  start_date&.strftime("%Y%m%d")
      issuer_ind_prem_start_date = @rcni_row[49]

      if ffm_ind_prem_start_date.blank?
        @overall_flag = "N"
        return [nil, ffm_ind_prem_start_date, "D"]
      end

      return [ffm_ind_prem_start_date, issuer_ind_prem_start_date, "D"] if ["N", "C"].include?(@policy.effectuation_status)

      match_data = ffm_ind_prem_start_date == issuer_ind_prem_start_date ? "M" : "I"
      @overall_flag = "N" if match_data == "I"
      [ffm_ind_prem_start_date, issuer_ind_prem_start_date, match_data]
    end

    def individual_premium_end_date
      # If Subscriber, Member, or Policy are not found
      return [nil, @rcni_row[50], "D"] if @overall_flag == "R" || @overall_flag == "U" || @overall_flag == "B"

      # return [nil, @rcni_row[50], "U"] if @member.blank?
      # unprocessed policy
      if @overall_flag == "G"
        segment = fetch_segment(@member.coverage_start)
        end_date = segment&.effective_end_date
        unprocessed_individual_premium_end_date = end_date&.strftime("%Y%m%d")
        return [unprocessed_individual_premium_end_date, nil, "D"]
      end
      segment = fetch_segment(@rcni_row[37])
      end_date = segment&.effective_end_date

      ffm_ind_prem_end_date =  end_date&.strftime("%Y%m%d")
      issuer_ind_prem_end_date = @rcni_row[50]

      if ffm_ind_prem_end_date.blank?
        @overall_flag = "N"
        return [nil, ffm_ind_prem_end_date, "D"]
      end

      return [ffm_ind_prem_end_date, issuer_ind_prem_end_date, "D"] if ["N", "C"].include?(@policy.effectuation_status)

      if ffm_ind_prem_end_date == Date.today.end_of_year.strftime("%Y%m%d") && issuer_ind_prem_end_date.blank?
        return [ffm_ind_prem_end_date, issuer_ind_prem_end_date,
                "M"]
      end

      match_data = ffm_ind_prem_end_date == issuer_ind_prem_end_date ? "M" : "I"
      @overall_flag = "N" if match_data == "I"
      [ffm_ind_prem_end_date, issuer_ind_prem_end_date, match_data]
    end

    def premium_paid_status
      # If Subscriber, Member, or Policy are not found
      return [nil, @rcni_row[51], "D"] if @overall_flag == "R" || @overall_flag == "U" || @overall_flag == "B"

      # Next line likely unnecessary
      # return [nil, @rcni_row[51], "U"] if @policy.blank?
      # unprocessed policy
      unprocessed_premium_status = fetch_effectuation_status if @overall_flag == "G"
      return [unprocessed_premium_status, nil, "D"] if @overall_flag == "G"

      ffm_premium_status = fetch_effectuation_status
      issuer_premium_status = @rcni_row[51]
      return [ffm_premium_status, nil, "D"] unless @member.is_subscriber

      match_data = ffm_premium_status == issuer_premium_status ? "M" : "G"
      @overall_flag = "N" if match_data == "G" && @overall_flag != "R"
      [ffm_premium_status, issuer_premium_status, match_data]
    end

    def coverage_year
      # If Subscriber, Member, or Policy are not found
      return [nil, @rcni_row[53], "D"] if @overall_flag == "R" || @overall_flag == "U" || @overall_flag == "B"

      # return [nil, @rcni_row[53], "U"] if @policy.blank?

      # unprocessed policy
      if @overall_flag == "G"
        unprocessed_coverage_year = @policy.primary_subscriber.coverage_start.year.to_s
        return [unprocessed_coverage_year, nil, "D"]
      end
      ffm_coverage_year = @policy.primary_subscriber.coverage_start.year.to_s
      issuer_coverage_year = @rcni_row[53]
      match_data = ffm_coverage_year == issuer_coverage_year ? "M" : "I"
      [ffm_coverage_year, issuer_coverage_year, match_data]
    end

    def market_place_segment_id
      # If Subscriber, Member, or Policy are not found
      return nil if @overall_flag == "R" || @overall_flag == "U" || @overall_flag == "B"

      # return nil if @member.blank?
      # return nil if @policy.blank?

      subscriber = @policy.primary_subscriber
      date = @member.coverage_start.strftime("%Y%m%d")
      "#{subscriber.hbx_member_id}-#{@policy.enrollment_group_id}-#{date}"
    end

    def overall_indicator
      # If Subscriber, Member, or Policy are not found
      return "R" if @overall_flag == "R"
      # If Subscriber, Member, and Policy are found but no segment start date matches issuer benefit start date
      return "N" if @overall_flag == "B"
      return "U" if @overall_flag == "U"
      # return "G" if @rcni_row[8].blank?
      # unprocessed policy
      return "G" if @overall_flag == "G"

      @overall_flag
    end

    def insert_missing_policy_data(csv, valid_params, rcni_file_path)
      carrier_hios_id = valid_params[:payload][:carrier_hios_id]
      year = valid_params[:payload][:year]
      records = AuditReportDatum.where(hios_id: carrier_hios_id,
                                       year: year,
                                       status: "completed",
                                       report_type: "pre_audit",
                                       :'ard_policies.rcno_processed' => false)
      records.each do |record|
        policies = record.ard_policies
        policies.each do |policy|
          next if policy.rcno_processed

          policy_contract_result = AcaEntities::Contracts::Policies::PolicyContract.new.call(JSON.parse(policy.payload))

          if policy_contract_result.errors.present?
            @logger.error("enrollment_group_id: #{policy.policy_eg_id},
                            validations errors from AcaEntities: #{policy_contract_result.errors.messages} \n")
            Rails.logger.error("Errors for Policy in RCNO report for id - #{policy.policy_eg_id}")
          end
          policy_entity = AcaEntities::Policies::Policy.new(policy_contract_result.to_h)

          rcni_first_row = File.readlines(rcni_file_path, chomp: true).first.split("|")
          @rcni_row = [rcni_first_row[0], rcni_first_row[1], rcni_first_row[2], rcni_first_row[3],
                       rcni_first_row[4], rcni_first_row[5], rcni_first_row[6]] + ([""] * 56)

          policy_entity.enrollees.each do |enrollee|
            @policy = policy_entity
            @member = enrollee
            @segments = enrollee.segments
            @overall_flag = "G"
            csv << insert_data
            @total_number_of_issuer_records += 1
          end
        end
      end
    end

    def insert_data
      first_name = compare_first_name
      middle_name = compare_middle_name
      last_name = compare_last_name
      dob = compare_dob
      gender = compare_gender
      ssn = compare_ssn
      sub_indicator = subscriber_indicator
      rel_to_sub_indicator = relation_to_subscriber_indicator
      exh_assigned_sub_id = exchange_assigned_subscriber_id
      exh_assigned_mem_id = exchange_assigned_member_id
      issuer_assigned_sub_id = issuer_assigned_subscriber_id
      issuer_assigned_mem_id = issuer_assigned_member_id
      exh_assigned_policy_id = exchange_assigned_policy_number
      issuer_assigned_policy_id = issuer_assigned_policy_number
      applied_aptc_amount = applied_aptc_value
      all_policy_total_premium_amount = total_premium_amount
      ind_premium_amount = individual_premium_amount

      [@rcni_row[0], @rcni_row[1], nil, @rcni_row[3], @rcni_row[4], @rcni_row[5], @rcni_row[6],
       first_name[0]&.first(35), first_name[1]&.first(35), first_name[2],
       middle_name[0]&.first(25), middle_name[1]&.first(25), middle_name[2],
       last_name[0]&.first(60), last_name[1]&.first(60), last_name[2],
       dob[0], dob[1], dob[2],
       gender[0], gender[1], gender[2],
       ssn[0], ssn[1], ssn[2],
       sub_indicator[0], sub_indicator[1], sub_indicator[2],
       rel_to_sub_indicator[0], rel_to_sub_indicator[1], rel_to_sub_indicator[2],
       exh_assigned_sub_id[0], exh_assigned_sub_id[1], exh_assigned_sub_id[2],
       exh_assigned_mem_id[0], exh_assigned_mem_id[1], exh_assigned_mem_id[2],
       issuer_assigned_sub_id[0], issuer_assigned_sub_id[1], issuer_assigned_sub_id[2],
       issuer_assigned_mem_id[0], issuer_assigned_mem_id[1], issuer_assigned_mem_id[2],
       exh_assigned_policy_id[0], exh_assigned_policy_id[1], exh_assigned_policy_id[2],
       issuer_assigned_policy_id[0], issuer_assigned_policy_id[1], issuer_assigned_policy_id[2],
       @member&.residential_address&.address_1&.gsub("|", "")&.first(55), @rcni_row[22]&.first(55), 'D',
       @member&.residential_address&.address_2&.gsub("|", "")&.first(55), @rcni_row[23]&.first(55), 'D',
       @member&.residential_address&.city&.gsub("|", "")&.first(30), @rcni_row[24]&.first(30), 'D',
       residential_address_state[0], residential_address_state[1], residential_address_state[2],
       residential_address_zip[0], residential_address_zip[1], residential_address_zip[2],
       @member&.mailing_address&.address_1&.gsub("|", "")&.first(55), @rcni_row[27]&.first(55),  'D',
       @member&.mailing_address&.address_2&.gsub("|", "")&.first(55), @rcni_row[28]&.first(55),  'D',
       @member&.mailing_address&.city&.gsub("|", "")&.first(30), @rcni_row[29]&.first(30), 'D',
       mailing_address_state[0], mailing_address_state[1], mailing_address_state[2],
       mailing_address_zip[0], mailing_address_zip[1], mailing_address_zip[2],
       residential_address_county[0], residential_address_county[1], residential_address_county[2],
       rating_area[0], rating_area[1], rating_area[2],
       phone_number, @rcni_row[34], 'D',
       tobacco_use_code(@member&.enrollee_demographics&.tobacco_use_code), @rcni_row[35], 'D',
       qhp_id_match[0], qhp_id_match[1], qhp_id_match[2],
       benefit_start_date[0], benefit_start_date[1], benefit_start_date[2],
       benefit_end_date[0], benefit_end_date[1], benefit_end_date[2],

       applied_aptc_amount[0], applied_aptc_amount[1], applied_aptc_amount[2],
       applied_aptc_start_date[0], applied_aptc_start_date[1], applied_aptc_start_date[2],
       applied_aptc_end_date[0], applied_aptc_end_date[1], applied_aptc_end_date[2],

       nil, @rcni_row[42], "D",
       applied_aptc_start_date[0], @rcni_row[43], "D",
       applied_aptc_end_date[0], @rcni_row[44], "D",

       all_policy_total_premium_amount[0], all_policy_total_premium_amount[1], all_policy_total_premium_amount[2],
       total_premium_start_date[0], total_premium_start_date[1], total_premium_start_date[2],
       total_premium_end_date[0], total_premium_end_date[1], total_premium_end_date[2],

       ind_premium_amount[0], ind_premium_amount[1], ind_premium_amount[2],
       individual_premium_start_date[0], individual_premium_start_date[1], individual_premium_start_date[2],
       individual_premium_end_date[0], individual_premium_end_date[1], individual_premium_end_date[2],
       premium_paid_status[0], premium_paid_status[1], premium_paid_status[2],
       overall_indicator, nil, nil,
       Date.today.strftime("%Y%m"), nil, @rcni_row[52],
       coverage_year[0], coverage_year[1], coverage_year[2],
       nil, @rcni_row[54], "D",
       nil, @rcni_row[55], "D",
       nil, @rcni_row[56], "D",
       nil, @rcni_row[57], "D",
       nil, @rcni_row[58], "D",
       nil, @rcni_row[59], "D",
       nil, @rcni_row[60], "D",
       nil, nil, nil,
       nil, @rcni_row[61], "D",
       nil, @rcni_row[62], "D",
       market_place_segment_id, nil, nil]
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/PerceivedComplexity
    # rubocop:enable Metrics/MethodLength

    def insert_total_record_data
      ["02", @rcni_row[1], "----------".gsub(/-/, " "),
       @rcni_row[3], @rcni_row[4], @rcni_row[5], @rcni_row[6],
       @total_number_of_issuer_records,
       @total_subscribers, @total_dependents, format('%.2f', @total_premium_amount),
       format('%.2f', @total_applied_premium_amount), "A"]
    end
  end
  # rubocop:enable Metrics/ClassLength
end
