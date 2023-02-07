# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Tax1095a
  # Fetch and publish IRS Groups
  class FetchAndPublishIrsGroups
    include EventSource::Command
    include Dry::Monads[:result, :do]

    PROCESSING_BATCH_SIZE = 1000

    TAX_FORM_TYPES = %w[IVL_TAX Corrected_IVL_TAX IVL_VTA IVL_CAP].freeze

    PRODUCT_CRITERIA = { "IVL_TAX" => "non_catastrophic_product_ids",
                         "IVL_CAP" => "catastrophic_product_ids" }.freeze

    # params {tax_year: ,tax_form_type: }
    def call(params)
      values = yield validate(params)
      irs_groups = yield fetch_irs_groups(values)
      irs_group_exclusion_set = yield build_irs_groups_to_exclude(values)
      result = yield process(irs_groups, values, irs_group_exclusion_set)
      Success(result)
    end

    private

    def validate(params)
      @batch_size = params[:batch_size] if params[:batch_size]

      return Failure("valid tax form type is not present") unless TAX_FORM_TYPES.include?(params[:tax_form_type])
      return Failure("tax_year is not present") unless params[:tax_year].present?
      return Failure("exclusion_list required") unless params[:exclusion_list] # array of primary hbx ids
      return Failure("transmission_kind required") unless params[:transmission_kind]

      Success(params)
    end

    def fetch_irs_groups(values)
      query = query_criteria(values[:tax_year], instance_eval(PRODUCT_CRITERIA[values[:tax_form_type]]))
      policies = InsurancePolicies::AcaIndividuals::InsurancePolicy.where(query)
      irs_groups = ::InsurancePolicies::AcaIndividuals::IrsGroup.where(:_id.in => policies&.pluck(:irs_group_id)&.uniq)

      return Failure("No irs_groups are not found for the given tax_year: #{values[:tax_year]}") unless irs_groups.present?

      Success(irs_groups)
    end

    def query_criteria(tax_year, eligible_product_ids)
      { :start_on.gte => Date.new(tax_year, 1, 1),
        :aasm_state.nin => ["canceled"],
        :carrier_policy_id.ne => nil, :insurance_product_id.in => eligible_product_ids }
    end

    def non_catastrophic_product_ids
      InsurancePolicies::InsuranceProduct.where(:coverage_type => 'health',
                                                :metal_level.nin => ["catastrophic"]).pluck(:_id).flatten
    end

    def catastrophic_product_ids
      InsurancePolicies::InsuranceProduct.where(:coverage_type => 'health', :metal_level => "catastrophic").pluck(:_id).flatten
    end

    def build_irs_groups_to_exclude(values)
      ids = People::Person.where(:hbx_id.in => values[:exclusion_list]).pluck(:_id)
      insurance_policies = InsurancePolicies::InsuranceAgreement.where(:contract_holder_id.in => ids)
                                                                .flat_map(&:insurance_policies)

      irs_group_exclusion_set_hash = insurance_policies.each_with_object({}) do |insurance_policy, irs_group_exclusion_set|
        irs_group_exclusion_set[insurance_policy.irs_group.irs_group_id] = insurance_policy.policy_id
      end

      Success(irs_group_exclusion_set_hash)
    end

    def policies_by_primary(primary_hbx_id, values)
      primary_person = Person.find_for_member_id(primary_hbx_id)
      return [] if primary_person.blank?

      fetch_glue_policies_for_year(values, primary_person.policies).success
    end

    def processing_batch_size
      @batch_size || PROCESSING_BATCH_SIZE
    end

    def process(irs_groups, values, irs_group_exclusion_set)
      query_offset = 0

      while irs_groups.count > query_offset
        batched_irs_groups = irs_groups.skip(query_offset).limit(processing_batch_size)

        IrsYearlyBatchProcessDirector.new.call(
          irs_groups: batched_irs_groups.pluck(:irs_group_id),
          irs_groups_to_exclude: irs_group_exclusion_set,
          tax_year: values[:tax_year],
          tax_form_type: values[:tax_form_type],
          transmission_kind: values[:transmission_kind]
        )

        query_offset += processing_batch_size
        p "Processed #{query_offset} irs_groups."
      end

      Success(true)
    end
  end
end
