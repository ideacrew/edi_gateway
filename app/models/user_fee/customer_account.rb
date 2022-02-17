# frozen_string_literal: true

module UserFee
  # Subscriber or other party that receives bills for the associated
  # {Policy}
  class CustomerAccount
    include Mongoid::Document
    include Mongoid::Timestamps

    field :account_id, type: String
    field :is_active, type: Boolean

    embeds_one :customer, class_name: 'UserFee::Member'
    embeds_many :policies, class_name: 'UserFee::Policy'
    accepts_nested_attributes_for :customer, :policies

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
