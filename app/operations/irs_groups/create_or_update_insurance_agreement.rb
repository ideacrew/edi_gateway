# frozen_string_literal: true

# rubocop:disable Metrics/AbcSize
# rubocop:disable Metrics/ClassLength

module IrsGroups
  # persist insurance agreements and nested models
  class CreateOrUpdateInsuranceAgreement
    include Dry::Monads[:result, :do, :try]
    include EventSource::Command

    def call(params)
      values = yield validate(params)
      insurance_provider_hash = yield persist_insurance_provider(values)
      insurance_product_hash = yield persist_insurance_product(insurance_provider_hash, values)
      insurance_agreement_hash =
        yield persist_insurance_agreement(values, insurance_provider_hash, insurance_product_hash)
      insurance_policy = yield persist_insurance_policy(values, insurance_agreement_hash, insurance_product_hash)

      Success(insurance_policy)
    end

    private

    def validate(params)
      return Failure('Unable to find contract_holder_hash') if params[:contract_holder_hash].blank?
      return Failure('Unable to find irs_group_hash') if params[:irs_group_hash].blank?
      return Failure('Unable to find policy') if params[:policy].blank?

      Success(params)
    end

    def build_insurance_product_hash(glue_policy)
      plan = glue_policy.plan
      {
        name: plan.name,
        hios_plan_id: plan.hios_plan_id,
        plan_year: plan.year,
        coverage_type: plan.coverage_type,
        metal_level: plan.metal_level,
        market_type: plan.market_type,
        ehb: plan.ehb
      }
    end

    def build_insurance_policy_hash(glue_policy)
      {
        start_on: glue_policy.policy_start,
        end_on: glue_policy.policy_end,
        policy_id: glue_policy.eg_id,
        aasm_state: glue_policy.aasm_state,
        carrier_policy_id: glue_policy.subscriber.cp_id,
        term_for_np: glue_policy.term_for_np
      }
    end

    def persist_insurance_provider(values)
      product_hash = build_insurance_product_hash(values[:policy])
      InsurancePolicies::InsuranceProviders::FindOrCreate.new.call(values.merge(product_hash: product_hash))
    end

    def persist_insurance_product(provider_hash, values)
      product_hash = build_insurance_product_hash(values[:policy])
      InsurancePolicies::InsuranceProducts::FindOrCreate.new.call(
        values.merge(provider_hash: provider_hash, product_hash: product_hash)
      )
    end

    # rubocop:disable Metrics/MethodLength
    def persist_insurance_agreement(values, provider_hash, product_hash)
      insurance_policy_hash = build_insurance_policy_hash(values[:policy])

      InsurancePolicies::InsuranceAgreements::FindOrCreate.new.call(
        values.merge(
          provider_hash: provider_hash,
          product_hash: product_hash,
          insurance_policy_hash: insurance_policy_hash
        )
      )
    end

    # rubocop:enable Metrics/MethodLength

    def policy_entity_for(policy_hash)
      AcaEntities::InsurancePolicies::AcaIndividuals::InsurancePolicy.new(policy_hash)
    end

    def policy_details_changed?(insurance_policy, glue_policy, product_hash)
      policy_attributes = insurance_policy.as_json(include: [:insurance_product]).deep_symbolize_keys
      policy_attributes.merge!(start_on: insurance_policy.start_on, end_on: insurance_policy.end_on)
      policy_attributes[:insurance_product][:ehb] = policy_attributes[:insurance_product][:ehb].to_f
      current_policy_entity = policy_entity_for(policy_attributes)

      incoming_policy_attributes = build_insurance_policy_hash(glue_policy)
      product_hash[:ehb] = product_hash[:ehb].to_f
      incoming_policy_attributes[:insurance_product] = product_hash
      incoming_policy_entity = policy_entity_for(incoming_policy_attributes)

      (current_policy_entity <=> incoming_policy_entity)[:diff] != 0
    end

    def update_insurance_policy(glue_policy, product_hash)
      insurance_policy = ::InsurancePolicies::AcaIndividuals::InsurancePolicy.where(policy_id: glue_policy.eg_id).first
      if policy_details_changed?(insurance_policy, glue_policy, product_hash)
        insurance_policy.update!(
          start_on: glue_policy.policy_start,
          end_on: glue_policy.policy_end,
          aasm_state: glue_policy.aasm_state,
          carrier_policy_id: glue_policy.subscriber.cp_id,
          term_for_np: glue_policy.term_for_np
        )
      end

      Success(
        insurance_policy.as_json(include: %i[insurance_product insurance_agreement enrollments]).deep_symbolize_keys
      )
    end

    def persist_insurance_policy(values, agreement_hash, product_hash)
      insurance_policy =
        InsurancePolicies::AcaIndividuals::InsurancePolicies::Find.new.call({ policy_id: values[:policy].eg_id })
      return update_insurance_policy(values[:policy], product_hash) if insurance_policy.success?

      policy_hash_params = build_insurance_policy_hash(values[:policy])
      policy_hash_params.merge!(
        insurance_agreement: agreement_hash,
        insurance_product: product_hash,
        irs_group: values[:irs_group_hash]
      )
      InsurancePolicies::AcaIndividuals::InsurancePolicies::Create.new.call(policy_hash_params)
    end
  end
end
# rubocop:enable Metrics/AbcSize
# rubocop:enable Metrics/ClassLength
