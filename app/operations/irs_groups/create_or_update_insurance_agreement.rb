# frozen_string_literal: true

module IrsGroups
  # persist insurance agreements and nested models
  class CreateOrUpdateInsuranceAgreement
    include Dry::Monads[:result, :do, :try]
    include EventSource::Command

    def call(params)
      validated_params = yield validate(params)
      glue_policy = validated_params[:policy]
      insurance_provider_hash = yield persist_insurance_provider(glue_policy)
      insurance_product_hash = yield persist_insurance_product(insurance_provider_hash, glue_policy)
      person_hash = yield persist_contract_holder(glue_policy)
      irs_group_hash = yield persist_irs_group(glue_policy)
      insurance_agreement_hash = yield persist_insurance_agreement(glue_policy, person_hash, insurance_provider_hash,
                                                                   insurance_product_hash)
      insurance_policy = yield persist_insurance_policy(glue_policy, insurance_agreement_hash, insurance_product_hash,
                                                        irs_group_hash)

      Success(insurance_policy)
    end

    private

    def validate(params)
      Success(params)
    end

    def build_insurance_product_hash(glue_policy)
      plan = glue_policy.plan
      { name: plan.name, hios_plan_id: plan.hios_plan_id, plan_year: plan.year,
        coverage_type: plan.coverage_type, metal_level: plan.metal_level,
        market_type: plan.market_type, ehb: plan.ehb }
    end

    def build_insurance_policy_hash(glue_policy)
      { start_on: glue_policy.policy_start, end_on: glue_policy.policy_end,
        policy_id: glue_policy.eg_id,
        hbx_enrollment_ids: glue_policy.hbx_enrollment_ids,
      }
    end

    def map_person_to_contract_params(person_hash)
      person_hash.merge!(person_name: person_hash[:name])

      person_hash[:addresses].collect do |address|
        address[:city]  = address[:city_name]
      end
      person_hash
    end

    def persist_insurance_provider(policy)
      carrier = policy.carrier
      params = { hios_id: policy.plan.hios_plan_id.split("ME")[0], title: carrier.name, fein: carrier.fein }
      provider = InsurancePolicies::InsuranceProviders::Find.new.call(params)
      return provider if provider.success?

      product_hash = build_insurance_product_hash(policy)
      params.merge!(insurance_products: [product_hash])
      InsurancePolicies::InsuranceProviders::Create.new.call(params)
    end

    def persist_insurance_product(provider_hash, glue_policy)
      plan = glue_policy.plan
      params_to_find = { hios_plan_id: plan.hios_plan_id, plan_year: plan.year }
      product = InsurancePolicies::InsuranceProducts::Find.new.call(params_to_find)
      return product if product.success?

      params_hash = build_insurance_product_hash(glue_policy)
      params_hash.merge!(insurance_provider_hash: provider_hash)
      InsurancePolicies::InsuranceProducts::Create.new.call(params_hash)
    end

    def persist_contract_holder(glue_policy)
      glue_person = find_person_from_glue_policy(glue_policy)
      result = People::Persons::Find.new.call({ hbx_id: glue_person.authority_member_id })
      return result if result.success?

      People::Persons::Create.new.call({person: glue_person})
    end

    def persist_insurance_agreement(policy, person_hash, provider_hash, product_hash)
      plan_year = policy.plan.year
      agreement = InsurancePolicies::InsuranceAgreements::Find.
        new.call({ plan_year: plan_year,
                   insurance_provider_id: provider_hash[:id],
                   contract_holder_id: person_hash[:id]})
      return agreement if agreement.success?

      person_params_hash = map_person_to_contract_params(person_hash)
      policy_params = build_insurance_policy_hash(policy)
      policy_params.merge!(insurance_product: product_hash)
      InsurancePolicies::InsuranceAgreements::Create.new.call({ plan_year: plan_year,
                                                                contract_holder: person_params_hash,
                                                                insurance_provider: provider_hash,
                                                                insurance_policy: policy_params })
    end

    def persist_irs_group(glue_policy)
      date = glue_policy.subscriber.coverage_start.beginning_of_year
      return Success({} )if non_eligible_policy(glue_policy)

      glue_person = find_person_from_glue_policy(glue_policy)
      irs_group_id = construct_irs_group_id(date.year.to_s.last(2), glue_person.authority_member_id)

      irs_group = InsurancePolicies::AcaIndividuals::IrsGroups::Find.
        new.call({scope_name: :by_irs_group_id, criterion: irs_group_id })
      return irs_group if irs_group.success?

      InsurancePolicies::AcaIndividuals::IrsGroups::Create.new.call({irs_group_id: irs_group_id,
                                                                    start_on: date})
    end


    def persist_insurance_policy(glue_policy, agreement_hash, product_hash, irs_group_hash)
      insurance_policy = InsurancePolicies::AcaIndividuals::InsurancePolicies::Find.
        new.call({ policy_id: glue_policy.eg_id })
      return insurance_policy if insurance_policy.success?

      policy_hash_params = build_insurance_policy_hash(glue_policy)
      policy_hash_params.merge!(insurance_agreement: agreement_hash,
                                insurance_product: product_hash,
                                irs_group: irs_group_hash)
      InsurancePolicies::AcaIndividuals::InsurancePolicies::Create.new.call(policy_hash_params)
    end

    def find_person_from_glue_policy(policy)
      if policy.responsible_party.present?
        Person.where("responsible_parties._id" => policy.responsible_party_id).first
      else
        policy.subscriber.person
      end
    end

    def construct_irs_group_id(year, hbx_id)
      total_length_excluding_year = 14
      hbx_id_number = format("%0#{total_length_excluding_year}d", hbx_id)
      year + hbx_id_number
    end

    def non_eligible_policy(pol)
      return true if pol.canceled?
      return true if pol.kind == "coverall"
      return true if pol.plan.coverage_type == "dental"
      return true if pol.plan.metal_level == "catastrophic"
      return true if pol.subscriber.cp_id.blank?

      false
    end
  end
end
