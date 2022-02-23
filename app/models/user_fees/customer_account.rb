# frozen_string_literal: true

module UserFees
  # Account tied to a customer who is responsible for premium billing for the
  #   members enrolled under the associated policies.  The customer may be an
  #   insured member or another contracting party
  class CustomerAccount
    include Mongoid::Document
    include Mongoid::Timestamps

    field :customer_role, type: String
    field :account_id, type: String
    field :is_active, type: Boolean, default: true

    embeds_one :customer, class_name: '::UserFees::Member', cascade_callbacks: true
    embeds_many :tax_households, class_name: '::UserFees::TaxHousehold', cascade_callbacks: true
    embeds_many :policies, class_name: 'UserFees::Policy', cascade_callbacks: true
    accepts_nested_attributes_for :customer, :policies, :tax_households

    scope :by_active, -> { where(is_active: true) }
    scope :by_customer_role, ->(value) { where(customer_role: value[:value]) }
    scope :by_customer_id, ->(value) { where('customer.hbx_id': value[:value]) }
    scope :by_id, ->(value) { value[:_id] }

    index({ is_active: 1 }, { name: 'is_active_index' })
    index({ customer_role: 1 }, { name: 'customer_role_index' })
    index({ 'customer.hbx_id': 1 }, { unique: true, name: 'customer_hbx_id_index' })
    index({ 'policies.subscriber_hbx_id': 1 }, { name: 'subscribers_hbx_id_index' })
    index({ 'policies.insurer.hios_id': 1 }, { name: 'insurers_hios_id_index' })
    index({ 'policies.start_on': 1 }, { name: 'policies_start_on_index' })
    index({ 'policies.end_on': 1 }, { sparse: true, name: 'policies_end_on_index' })

    def account
      Account.find(self.account_id)
    end

    def to_entity
      serializable_hash.merge('_id' => id.to_s).deep_symbolize_keys
    end

    def to_s
      [raw_header, raw_body, raw_footer].join('\n\n')
    end

    def data_elements
      []
    end
  end
end
