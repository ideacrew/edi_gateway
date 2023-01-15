# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Tax1095a
  # Fetch and publish IRS Groups
  class FetchAndPublishIrsGroups
    include EventSource::Command
    include Dry::Monads[:result, :do]

    TAX_FORM_TYPES = %w[IVL_TAX Corrected_IVL_TAX IVL_VTA IVL_CAP].freeze

    PRODUCT_CRITERIA = { "IVL_TAX" => "non_catastrophic_product_ids",
                         "IVL_CAP" => "catastrophic_product_ids" }.freeze

    # params {tax_year: ,tax_form_type: }
    def call(params)
      tax_year, tax_form_type = yield validate(params)
      irs_group_ids = yield fetch_irs_groups(tax_year, tax_form_type)
      # yield publish(irs_group_ids, tax_year, tax_form_type)

      Success(true)
    end

    private

    def validate(params)
      tax_form_type = params[:tax_form_type]
      tax_year = params[:tax_year]
      return Failure("Valid tax form type is not present") unless TAX_FORM_TYPES.include?(tax_form_type)
      return Failure("tax_year is not present") unless tax_year.present?

      Success([tax_year, tax_form_type])
    end

    def fetch_irs_groups(tax_year, tax_form_type)
      query = query_criteria(tax_year, instance_eval(PRODUCT_CRITERIA[tax_form_type]))
      policies = InsurancePolicies::AcaIndividuals::InsurancePolicy.where(query)

      irs_group_ids = policies&.pluck(:irs_group_id)
      return Failure("No irs_groups are not found for the given tax_year: #{tax_year}") unless irs_group_ids.present?

      Success(irs_group_ids)
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

    def publish(irs_group_ids, tax_year, tax_form_type)
      event_key = "insurance_policies.tax1095a_payload.requested"
      irs_group_ids.each do |irs_group_id|
        params = { payload: { tax_year: tax_year, tax_form_type: tax_form_type, irs_group_id: irs_group_id },
                   event_name: event_key }

        result = ::Tax1095a::PublishRequest.new.call(params)
        if result.failure?
          return Failure("Failed to publish for event #{event_key}, with params: #{params}, failure: #{result.failure}")
        end
      end

      Success(true)
    end
  end
end
