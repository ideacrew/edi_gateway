# frozen_string_literal: true

module PolicyInventory
  # Import an outside span snapshot.
  class ImportSpanRecord
    send(:include, Dry::Monads[:result, :do, :try])

    def call(params)
      validated_params = yield validate_params(params)
      _already_exists = yield search_existing_spans_by_id(validated_params[:coverage_span][:enrollment_id])
      create_record(validated_params)
    end

    def validate_params(params)
      param_result = PolicyInventory::ImportSpanRecordContract.new.call(params)
      param_result.success? ? Success(param_result.values) : Failure(param_result.errors)
    end

    def create_record(params)
      candidates = search_for_candidate_matches(params)
      if candidates.any?
        matched_policy = yield check_candidate_matchups(candidates, params)
        if matched_policy
        else
          create_new_policy(params)
        end
      else
        create_new_policy(params)
      end
    end

    def create_new_policy(params)
      create_command = yield build_create_policy_command(params)
      Try do
        Sequent.command_service.execute_commands create_command
      end
    end

    def check_candidate_matchups(candidates, params)
      new_span = build_coverage_span(params)
      match_by_date = candidates.select do |can|
        dates_match?(can, new_span)
      end
      return Success(nil) if !match_by_date.any?
      remaining_matches = match_by_tobacco_status(match_by_date, new_span)
      remaining_matches.many? ? Fail(:too_many_matches) : Success(remaining_matches.first)
    end

    def match_by_tobacco_status(candidates, new_span)
      candidates.reject do |c|
        tu_hash = Hash.new
        c.coverage_span_records.flat_map(&:coverage_span_enrollee_records).each do |en|
          tu_hash[en.hbx_member_id] = en.tobacco_usage
        end
        new_span.enrollees.any? do |nse|
          tu_hash.has_key?(nse.hbx_member_id) && (tu_hash[nse.hbx_member_id] != nse.tobacco_usage)
        end
      end
    end

    def dates_match?(candidate, new_span)
      # Check for days end-to-end
      return false if (candidate.policy_end.present? && (candidate.policy_end < (new_span.coverage_start - 1.day)))
      return false if (new_span.coverage_end.present? && (new_span.coverage_end < (candidate.policy_start - 1.day)))
      true
    end

    def search_existing_spans_by_id(span_id)
      span_record = Policies::CoverageSpanRecord.where(enrollment_id: span_id).first
      span_record.present? ? Failure("Span already exists.") : Success(:ok)
    end

    def search_for_candidate_matches(params)
      subscriber_id = params[:subscriber_hbx_id]
      product_hios_id = params[:product][:hios_id]
      product_year = params[:product][:coverage_year]
      Policies::PolicyRecord.where(
        subscriber_hbx_id: subscriber_id,
        product_hios_id: product_hios_id,
        product_coverage_year: product_year
      )
    end

    def build_coverage_span(params)
      enrollees = params[:coverage_span][:enrollees].map do |en_hash|
        ::Policies::ValueObjects::Enrollee.new(en_hash)
      end
      span_params = params[:coverage_span].except(:enrollees)
      ::Policies::ValueObjects::CoverageSpan.new(span_params.merge({enrollees: enrollees}))
    end

    def build_create_policy_command(params)
      command = ::Policies::Commands::CreatePolicy.create(
        params[:policy_identifier],
        params[:subscriber_hbx_id],
        build_coverage_span(params),
        nil,
        ::Policies::ValueObjects::Product.new(params[:product]),
        params[:responsible_party_hbx_id]
      )
      command.valid? ? Success(command) : Failure(command.errors)
    end
  end
end