# frozen_string_literal: true

module InsurancePolicies
  module AcaIndividuals
    class PlanYearsProducts
      belongs_to :plan_year
      belongs_to :product
    end
  end
end
