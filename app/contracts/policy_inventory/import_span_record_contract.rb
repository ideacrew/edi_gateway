# frozen_string_literal: true

module PolicyInventory
  class ImportSpanRecordContract < ::Dry::Validation::Contract
    params do
      required(:subscriber_hbx_id).filled(:string)
      required(:policy_identifier).filled(:string)
      optional(:responsible_party_hbx_id).maybe(:string)
      required(:product).filled(:hash) do
        required(:hios_id).filled(:string)
        required(:coverage_year).filled(:string)
      end
      required(:coverage_span).filled(:hash) do
        required(:enrollment_id).filled(:string)
        required(:total_cost).filled(:string)
        required(:responsible_amount).filled(:string)
        optional(:applied_aptc).maybe(:string)
        optional(:employer_assistance_amount).maybe(:string)
        required(:coverage_start).filled(:date_time)
        optional(:coverage_end).maybe(:date_time)
        required(:enrollees).value(:array, min_size?: 1).each do
          hash do
            required(:hbx_member_id).filled(:string)
            required(:premium).filled(:string)
            required(:relationship).filled(:string)
            optional(:rate_schedule_date).maybe(:date_time)
            required(:tobacco_usage).filled(:string)
          end
        end
      end
    end
  end
end