# frozen_string_literal: true

module UserFees
  # Account tied to a customer who is responsible for premium billing for the
  #   members enrolled under the associated policies.  The customer may be an
  #   insured member or another contracting party
  class InsuranceCoverage
    include Mongoid::Document
    include Mongoid::Timestamps

    embeds_many :tax_households, class_name: '::UserFees::TaxHousehold', cascade_callbacks: true
    embeds_many :policies, class_name: 'UserFees::Policy', cascade_callbacks: true
    accepts_nested_attributes_for :policies, :tax_households

    field :hbx_id, type: String
    field :is_active, type: Boolean, default: true

    validate :passes_contract_validation
    validates :hbx_id, presence: true

    scope :policy,
          ->(customer: nil, policy: nil) {
            where(hbx_id: customer[:hbx_id]).and('policies.exchange_assigned_id': policy[:exchange_assigned_id])
          }
    scope :tax_household,
          ->(customer: nil, tax_houshold: nil) {
            where(hbx_id: customer[:hbx_id]).and(
              'tax_housholds.exchange_assigned_id': tax_household[:exchange_assigned_id]
            )
          }

    scope :subscriber_id,
          ->(hbx_id, subscriber_hbx_id) { where(hbx_id: hbx_id).and('policies.subscriber_hbx_id': subscriber_hbx_id) }
    scope :insurer_hios_id, ->(hios_id) { where('policies.insurer.hios_id': hios_id) }
    scope :product_id, ->(hbx_qhp_id) { where('policies.product.hbx_qhp_id': hbx_qhp_id) }
    scope :active, -> { where(is_active: true) }

    # scope :by_start_on, lambda do |value|
    #   where({ 'policies.start_on': value[:value] })
    # end

    # scope :by_end_on, lambda do |value|
    #   where('policies.end_on': value[:value])
    # end

    index({ hbx_id: 1, 'policies.exchange_assigned_id': 1 }, { unique: true, name: 'hbx_id_policy_id_index' })
    index({ hbx_id: 1, 'policies.subscriber_hbx_id': 1 }, { name: 'subscribers_hbx_id_index' })
    index({ hbx_id: 1, 'policies.start_on': 1 }, { name: 'policies_start_on_index' })
    index({ hbx_id: 1, 'policies.end_on': 1 }, { sparse: true, name: 'policies_end_on_index' })
    index({ 'policies.insurer.hios_id': 1 }, { name: 'insurers_hios_id_index' })
    index({ 'policies.product.hbx_qhp_id': 1 }, { name: 'product_id_index' })
    index({ is_active: 1 }, { name: 'is_active_index' })

    def to_hash
      serializable_hash.merge('_id' => id.to_s).deep_symbolize_keys
    end

    private

    def passes_contract_validation
      result = AcaEntities::Ledger::Contracts::InsuranceCoverageContract.new.call(self.to_hash)
      errors.add(:base, result.errors) if result.failure?
    end
  end
end
