# frozen_string_literal: true

module UserFee
  class CustomerAccount
    include Mongoid::Document
    include Mongoid::Timestamps

    field :account_id, type: String
    field :is_active, type: Boolean

    embeds_one :member, as: :customer, class_name: 'UserFee::Member'
    embeds_many :policies, class_name: 'UserFee::Policy'
    accepts_nested_attributess_for :customer, :policy

    def account
      Account.find(self.account_id)
    end
  end
end
