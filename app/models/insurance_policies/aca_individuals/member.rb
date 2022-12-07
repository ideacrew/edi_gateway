# frozen_string_literal: true

module InsurancePolicies
  module AcaIndividuals
    class Member
      include Mongoid::Document
      include Mongoid::Timestamps

      field :hbx_member_id, type: String
      field :insurer_assigned_id, type: String
      field :ssn, type: String
      field :dob, type: Date
      field :gender, type: String
      field :relationship_code, type: String

      belongs_to :insurance_agreement, class_name: "InsurancePolicies::AcaIndividuals::InsuranceAgreement",
                 inverse_of: :contract_holder, optional: true

      embeds_one :person_name, class_name: 'InsurancePolicies::AcaIndividuals::PersonName', cascade_callbacks: true
      accepts_nested_attributes_for :person_name

      embeds_many :emails, class_name: 'InsurancePolicies::AcaIndividuals::Email', cascade_callbacks: true
      accepts_nested_attributes_for :emails, allow_destroy: true

      embeds_many :addresses, class_name: 'InsurancePolicies::AcaIndividuals::Address', cascade_callbacks: true
      accepts_nested_attributes_for :addresses, allow_destroy: true

      embeds_many :phones, class_name: 'InsurancePolicies::AcaIndividuals::Phone', cascade_callbacks: true
      accepts_nested_attributes_for :phones, allow_destroy: true

      def primary_person
        Person.where(authority_member_id: self.hbx_member_id).first
      end
    end
  end
end
