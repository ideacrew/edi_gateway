# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Tax1095a
  # Publish class will build event and publish the payload
  class PublishFamilyPayload
    include Dry::Monads[:result, :do, :try]
    include EventSource::Command

    TRANSMISSION_KINDS = ['1095a'].freeze

    MAP_FORM_TYPE_TO_EVENT = {
      "IVL_CAP" => "catastrophic_payload_generated"
    }.freeze

    def call(params)
      values = yield validate(params)
      irs_group = yield fetch_irs_group(values)
      family_hash = yield construct_cv3_family(values)
      insurance_policies = yield fetch_insurance_policies(irs_group, values)
      transformed_family_hash = yield transform_family_payload(family_hash, values, insurance_policies)
      event = yield build_event(transformed_family_hash, values)
      result = yield publish(event)

      Success(result)
    end

    private

    def validate(params)
      errors = []
      params[:transmission_kind] ||= 'all'

      errors << "tax_year required" unless params[:tax_year]
      errors << "tax_form_type required" unless params[:tax_form_type]
      errors << "irs_group_id required" unless params[:irs_group_id]
      unless TRANSMISSION_KINDS.include?(params[:transmission_kind])
        errors << "transmission_kind should be one of #{TRANSMISSION_KINDS.join(',')}"
      end

      errors.empty? ? Success(params) : Failure(errors)
    end

    def fetch_irs_group(values)
      result = ::InsurancePolicies::AcaIndividuals::IrsGroup.where(irs_group_id: values[:irs_group_id])
      return Failure("Unable to fetch IRS group for irs_group_id: #{values[:irs_group_id]}") unless result.present?

      Success(result.first)
    end

    def construct_cv3_family(values)
      cv3_payload = ::Tax1095a::Transformers::InsurancePolicies::Cv3Family.new.call(
        {
          tax_year: values[:tax_year],
          tax_form_type: values[:tax_form_type],
          irs_group_id: values[:irs_group_id]
        }
      )
      return Failure("Unable to construct cv3 payload for irs_group_id: #{values[:irs_group_id]}") if cv3_payload.failure?

      Success(cv3_payload.value!)
    end

    def fetch_insurance_policies(irs_group, values)
      result = irs_group.aca_individual_insurance_policies.select do |policy|
        policy.start_on.year == values[:tax_year].to_i &&
          policy.aasm_state != "canceled" &&
          policy.insurance_product.coverage_type == "health" &&
          policy.insurnace_product.metal_level == "catastrophic"
      end

      Success(result)
    end

    def transform_family_payload(family_hash, tax_year, insurance_policies)
      policy_hbx_ids = insurance_policies.pluck(:policy_hbx_id)
      insurance_agreements = family_hash[:households][0][:insurance_agreements]
      family_hash[:households][0][:insurance_agreements] = fetch_insurance_agreements(insurance_agreements, tax_year)
      family_hash[:households][0][:insurance_agreements].each do |agreement|
        agreement[:insurance_policies] = fetch_valid_policies(agreement[:insurance_policies].flatten, policy_hbx_ids)
        agreement[:insurance_policies].each do |insurance_policy|
          insurance_policy[:aptc_csr_tax_households] = insurance_policy[:aptc_csr_tax_households].collect do |tax_household|
            tax_household
          end.compact
        end.compact
      end

      Success(family_hash)
    end

    def construct_covered_members_coverage_dates(covered_individuals, insurance_policy)
      covered_individuals.collect do |individual|
        individual[:coverage_start_on] = insurance_policy[:start_on]
        individual[:coverage_end_on] = insurance_policy[:start_on]
        individual
      end
    end

    def fetch_insurance_agreements(insurance_agreements, tax_year)
      insurance_agreements.select do |agreement|
        agreement[:plan_year].to_s == tax_year.to_s
      end
    end

    def fetch_valid_policies(insurance_policies, policy_hbx_ids)
      insurance_policies.select do |policy|
        policy_hbx_ids.include?(policy[:policy_id])
      end.flatten
    end

    def build_event(family_hash, values)
      event_name = MAP_FORM_TYPE_TO_EVENT[values[:tax_form_type]]
      event = event("events.families.tax_form1095a.#{event_name}",
                    attributes: family_hash, headers: { assistance_year: values[:reporting_year],
                                                        notice_type: values[:report_type],
                                                        affected_policies: values[:policy_hbx_ids] })
      Success(event)
    end

    def publish(event)
      event.success.publish

      Success("Successfully published the payload for event: #{events.map(&:name)}")
    end
  end
end
