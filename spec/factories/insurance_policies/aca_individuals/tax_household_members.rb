# frozen_string_literal: true

FactoryBot.define do
  factory :tax_household_member, class: InsurancePolicies::AcaIndividuals::TaxHouseholdMember do
    sequence(:hbx_id)
    is_subscriber { true }
    is_tax_filer { true }
    is_ia_eligible { true }
    relation_with_primary { "self" }
    tax_filer_status { "tax_filer" }
  end
end
