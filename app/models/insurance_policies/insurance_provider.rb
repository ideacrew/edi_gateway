# frozen_string_literal: true

module InsurancePolicies
  # A carrier who offers insurance policy products
  class InsuranceProvider
    include Mongoid::Document
    include Mongoid::Timestamps
    include DomainModels::Domainable

    has_many :insurance_products, class_name: 'InsurancePolicies::InsuranceProduct'

    field :title, type: String
    field :hios_id, type: String
    field :description, type: String
    field :text, type: String
    field :fein, type: String

    # has_many :insurance_agreements,
    #          class_name: 'InsurancePolicies::InsuranceAgreement',
    #          inverse_of: :insurance_provider,
    #          counter_cache: true

    index({ hios_id: 1 })
    index({ fein: 1 })

    def issuer_me_name
      carrier_names = {
        "311705652" => "ANTHEM HEALTH PLANS OF MAINE",
        "042452600" => "HARVARD PILGRIM HEALTH CARE INC",
        "453416923" => "MAINE COMMUNITY HEALTH OPTIONS",
        "010286541" => "Northeast Delta Dental"
      }
      carrier_names[self.fein]
    end
  end
end
