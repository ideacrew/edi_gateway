# frozen_string_literal: true

module InsurancePolicies
  module AcaIndividuals
    class AcaIndividuals
      ENROLLED_MEMBER_ELIGIBILITIES = %w[vlp_eligibility].freeze
      ENROLLED_MEMBER_EXEMPTIONS = %w[ssn_exempt age_off_exempt temporarily_out_of_state_exepmt homeless_exempt].freeze

      POLICY_ELIGIBILITIES = %w[ridp_eligible vlp_eligible aptc_csr_financial_assistance_eligible].freeze

      HEALTH_PRODUCT_FEATURES = %w[tobacco_user_feature].freeze
      HEALTH_PRODUCT_RATING_FACTORS = %w[tobacco_user_rating_factor].freeze

      DENTAL_PRODUCT_PREMIUM_RATINGS = %w[individual_premium_rating family_premium_rating].freeze
    end
  end
end
