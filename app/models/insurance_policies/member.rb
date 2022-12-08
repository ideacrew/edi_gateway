# frozen_string_literal: true

module InsurancePolicies
  # Member information
  class Member
    include Mongoid::Document
    include Mongoid::Timestamps

    embedded_in :enrolled_member, class_name: 'InsurancePolicies::EnrolledMember'

    # field :account_id, type: String
    field :member_id, type: String
    field :encypted_ssn, type: String
    field :dob, type: Date, as: :date_of_birth
    field :gender, type: String

    # field :subscriber_relationship_code, type: String
    field :active, type: Boolean, default: true

    embeds_many :exemptions do
      ssn_exempt
      age_off_exempt
    end

    field :disabled, type: Boolean, default: false
    field :age_off_exempt, type: Boolean, default: false
    field :homeless, type: Boolean, default: false

    field :temporarily_out_of_state, type: Boolean, default: false

    embeds_one :person, class_name: 'Person', cascade_callbacks: true
    accepts_nested_attributes_for :person

    embeds_many :former_genders, class_name: 'PersonGender', cascade_callbacks: true
    accepts_nested_attributes_for :gender_type

    embeds_many :documents

    embeds_many :roles

    embeds_many :eligibilities

    field :coverate_applicant, type: Boolean, default: true
    field :financial_assistance_applicant, type: Boolean, default: true

    def account
      Account.find(self.account_id)
    end

    def to_hash
      values = self.serializable_hash.deep_symbolize_keys.merge(id: id.to_s)
      AcaEntities::Ledger::Contracts::MemberContract.new.call(values).to_h
    end

    alias to_h to_hash
  end
end
