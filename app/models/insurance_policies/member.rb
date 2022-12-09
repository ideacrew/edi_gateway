# frozen_string_literal: true

module InsurancePolicies
  # A Person known to SBM but not necessarily enrolling for coverage (e.g. # Responsible Party
  class Member
    include Mongoid::Document
    include Mongoid::Timestamps

    embedded_in :enrolled_member, class_name: 'InsurancePolicies::EnrolledMember'

    field :member_id, type: String
    field :active, type: Boolean, default: true

    embeds_one :person, class_name: 'Person', cascade_callbacks: true
    accepts_nested_attributes_for :person

    embeds_many :former_genders, class_name: 'PersonGender', cascade_callbacks: true
    accepts_nested_attributes_for :gender_type

    embeds_many :documents

    embeds_many :roles

    # embeds_many :eligibilities

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
