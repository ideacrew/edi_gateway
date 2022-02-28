# frozen_string_literal: true

module UserFees
  # Account tied to a customer who is responsible for premium billing for the
  #   members enrolled under the associated policies.  The customer may be an
  #   insured member or another contracting party
  class InsuranceCoverage
    include Mongoid::Document
    include Mongoid::Timestamps

    validate :contract_validates

    def contract_validates
      result = AcaEntities::Ledger::Contracts::InsuranceCoverageContract.new.call(self.to_hash)
      errors.add(:base, result.errors) if result.failure?
    end

    # validates :customer_id, presence: true
    field :customer_id, type: Integer

    field :is_active, type: Boolean, default: true

    embeds_many :tax_households, class_name: '::UserFees::TaxHousehold', cascade_callbacks: true
    embeds_many :policies, class_name: 'UserFees::Policy', cascade_callbacks: true
    accepts_nested_attributes_for :policies, :tax_households

    scope :by_active, -> { where(is_active: true) }
    scope :by_subscriber_id, ->(value) { where('policies.subscriber_hbx_id': value[:value]) }

    # scope :by_start_on, lambda do |value|
    #   where({ 'policies.start_on': value[:value] })
    # end

    # scope :by_end_on, lambda do |value|
    #   where('policies.end_on': value[:value])
    # end
    scope :by_insurer_hios_id, ->(value) { where('policies.insurer.hios_id': value[:value]) }

    # index({ customer_id: 1 }, { name: 'customer_id_index' })
    index({ is_active: 1 }, { name: 'is_active_index' })
    index({ 'policies.subscriber_hbx_id': 1 }, { name: 'subscribers_hbx_id_index' })
    index({ 'policies.insurer.hios_id': 1 }, { name: 'insurers_hios_id_index' })
    index({ 'policies.start_on': 1 }, { name: 'policies_start_on_index' })
    index({ 'policies.end_on': 1 }, { sparse: true, name: 'policies_end_on_index' })

    def to_hash
      serializable_hash.merge('_id' => id.to_s).deep_symbolize_keys
    end
  end
end
