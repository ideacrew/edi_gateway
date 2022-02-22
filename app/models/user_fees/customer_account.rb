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

    embeds_one :customer, class_name: '::UserFees::Member'
    embeds_many :tax_households, class_name: '::UserFees::TaxHousehold'
    embeds_many :policies, class_name: 'UserFees::Policy'
    accepts_nested_attributes_for :customer, :policies, :tax_households

    scope :all, -> { exists(_id: true) }
    scope :active, -> { where(is_active: true) }

    # scope :by_customer_role, ->(value) { where(customer_role: value[:value]) }
    # scope :by_customer_id, ->(value) { where('customer.hbx_id': value[:value]) }
    # scope :by_subscriber_hbx_id, ->(value) { where('customer.subscriber_hbx_id': value[:value]) }
    scope :by_id, ->(value) { value[:_id] }

    index({ is_active: 1 }, { name: 'is_active_index' })

    index({ customer_role: 1 }, { name: 'customer_role_index' })
    index({ 'customer.hbx_id': 1 }, { name: 'customer_hbx_id_index' })
    index({ 'customer.subscriber_hbx_id': 1 }, { name: 'subscriber_hbx_id_index' })

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
