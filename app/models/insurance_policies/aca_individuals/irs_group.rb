# frozen_string_literal: true

module InsurancePolicies
  module AcaIndividuals
    class IrsGroup
      include Mongoid::Document
      include Mongoid::Timestamps

      field :irs_group_id, type: String
      field :start_on, type: Date
      field :end_on, type: Date

      embeds_many :insurance_agreements, class_name: "::InsurancePolicies::AcaIndividuals::InsuranceAgreement"

      accepts_nested_attributes_for :insurance_agreements
    end
  end
end