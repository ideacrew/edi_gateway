# frozen_string_literal: true

module InsurancePolicies
  module AcaIndividuals
    class Phone
      include Mongoid::Document
      include Mongoid::Timestamps

      field :kind, type: String
      field :number, type: String
      field :extension, type: String, default: ""
      field :primary, type: Boolean
      field :country_code, type: String, default: ""
      field :area_code, type: String, default: ""
      field :full_phone_number, type: String, default: ""

      embedded_in :member, class_name: 'InsurancePolicies::AcaIndividuals::Member'
    end
  end
end
