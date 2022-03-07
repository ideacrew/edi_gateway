# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Transforms
  class Cv3GdbTransaction
    include Dry::Monads[:result, :do]

    def call(params)
      validated_params = yield validate(params)
      @policies = yield convert_response_to_policy_entities(validated_params[:response])
      @customer = yield fetch_customer(validated_params[:subscriber_id])
      gdb_transaction_payload = yield construct_gdb_transaction_payload

      Success(gdb_transaction_payload)
    end

    private

    def validate(params)
      return Failure("Invalid Response") if params[:response].blank?
      return Failure("Please send in subscriber id") if params[:subscriber_id].blank?

      Success(params)
    end

    def construct_gdb_transaction_payload
      payload = {
        meta: construct_meta_information,
        customer: construct_customer_payload
      }
      Success(payload)
    end

    def construct_meta_information
      {
        transaction_header: transaction_header_payload
      }
    end

    def transaction_header_payload
      {
        code: 1,
        application_extract_time: DateTime.new,
        policy_maintenance_time: policy_maintenance_time
      }
    end

    def policy_maintenance_time
      latest_updated_policy = @policies.max_by(&:last_maintenance_date)
      date = latest_updated_policy.last_maintenance_date.strftime("%Y-%m-%d")
      time = latest_updated_policy.last_maintenance_time
      DateTime.strptime("#{date}#{time}", "%Y-%m-%d%H:%M:%S")
    end

    def construct_customer_payload
      {
        hbx_id: @subscriber_id,
        first_name: @customer&.first_name,
        last_name: @customer&.last_name,
        customer_role: "subscriber",
        account: construct_account_details,
        insurance_coverage: construct_coverage_details,
        is_active: true
      }
    end

    def convert_response_to_policy_entities(response_policies)
      policy_entities = []
      response_policies.each do |policy|
        policy_entities << fetch_policy_entity(policy)
      end
      return Failure("Invalid Policy response") if policy_entities.include?(false)

      Success(policy_entities)
    end

    def construct_account_details
      {
        id: "12345",
        number: "100101",
        name: "Accounts Receivable",
        kind: "asset"
      }
    end

    def construct_coverage_details
      {
        hbx_id: @subscriber_id,
        policies: construct_policies,
        is_active: true
      }
    end

    def construct_policies
      @policies.collect do |policy|
        {
          insurer: construct_insurer(policy),
          product: construct_product_information(policy),
          marketplace_segments: construct_segments(policy),
          exchange_assigned_id: policy.primary_subscriber&.hbx_member_id,
          rating_area_id: policy.rating_area,
          start_on: policy.coverage_start,
          end_on: policy.coverage_end,
          subscriber_hbx_id: policy.primary_subscriber&.hbx_member_id
        }
      end
    end

    def fetch_policy_entity(policy)
      policy_contract_result = AcaEntities::Contracts::Policies::PolicyContract.new.call(policy)
      return false if policy_contract_result.failure?

      AcaEntities::Policies::Policy.new(policy_contract_result.to_h)
    end

    def construct_segments(policy)
      segment_ids = policy.enrollees.flat_map(&:segments).map(&:id)
      segment_ids.collect do |segment_id|
        subscriber_segment = fetch_subscriber_segment(policy, segment_id)
        {
          segment: segment_id,
          total_premium_amount: subscriber_segment.total_premium_amount,
          total_premium_responsibility_amount: subscriber_segment.total_responsible_amount,
          start_on: subscriber_segment.effective_start_date,
          enrolled_members: construct_enrolled_members(policy, segment_id)
        }
      end
    end

    def fetch_subscriber_segment(policy, segment_id)
      subscriber = policy.primary_subscriber
      subscriber.segments.detect {|segment| segment.id == segment_id}
    end

    def construct_enrolled_members(policy, segment_id)
      enrolled_members = fetch_enrolled_members_for_segment(policy, segment_id)
      enrolled_members.collect do |member|
        {
          member: construct_member_details(policy, member),
          premium: construct_premium(member),
          start_on: member.coverage_start
        }
      end
    end

    def construct_premium(member)
      {
        amount: member.premium_amount
      }
    end

    def construct_member_details(policy, member)
      {
        hbx_id: member.hbx_member_id,
        subscriber_hbx_id: policy.exchange_subscriber_id,
        person_name: construct_person_name(member),
        ssn: member.enrollee_demographics.ssn,
        dob: member.enrollee_demographics.dob
      }
    end

    def construct_person_name(member)
      {
        first_name: member.first_name,
        middle_name: member.middle_name,
        last_name: member.last_name,
        name_sfx: member.name_suffix,
        start_on: member.coverage_start,
        end_on: member.coverage_end
      }
    end

    def fetch_enrolled_members_for_segment(policy, segment_id)
      policy.enrollees.select do |enrollee|
        enrollee.segments.any? {|segment| segment.id == segment_id }
      end
    end

    def construct_insurer(policy)
      {
        hios_id: policy.qhp_id.split("ME").first
      }
    end

    def construct_product_information(policy)
      {
        hbx_qhp_id: policy.qhp_id,
        effective_year: policy.coverage_start.year,
        kind: policy.insurance_line_code == "HLT" ? "health" : "dental"
      }
    end

    def fetch_customer(subscriber_id)
      @subscriber_id = subscriber_id
      enrollees = []
      @policies.each do |policy|
        enrollees << policy.enrollees.detect { |enrollee| enrollee.hbx_member_id == @subscriber_id}
      end

      Success(enrollees.uniq.first)
    end

    def construct_timestamps
      {}
    end
  end
end
