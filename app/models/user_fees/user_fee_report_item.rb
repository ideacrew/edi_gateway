# frozen_string_literal: true

module UserFees
  class UserFeeReportItem
    include Mongoid::Document
    include Mongoid::Timestamps

    field :hios_id, type: String
    field :customer_id, type: String
    field :policy_subscriber_hbx_id, type: String

    field :enrolled_member_hbx_id, type: String
    field :enrolled_member_last_name, type: String
    field :enrolled_member_first_name, type: String

    field :exchange_assigned_policy_id, type: String
    field :hbx_qhp_id, type: String
    field :marketplace_segment_id, type: String

    field :enrolled_member_billing_cycle_start_on, type: Date
    field :enrolled_member_billing_cycle_end_on, type: Date

    field :insurer_assigned_subscriber_id, type: String
    field :insurer_policy_id, type: String

    field :aptc_amount, type: BigDecimal

    field :policy_premium_amt, type: BigDecimal
    field :member_premium_amt, type: BigDecimal

    field :transaction_type, type: Integer
    field :user_fee_item_kind, type: String
    field :enrolled_member_premium_amount, type: BigDecimal
    field :enrolled_member_user_fee_amount, type: BigDecimal

    field :external_doc_reference, type: String
    field :sequence_value, type: Integer

    index({ hios_id: 1 })
    index({ policy_subscriber_hbx_id: 1 })
    # index(
    #   { enrolled_member_hbx_id: 1, exchange_assigned_policy_id: 1, hbx_qhp_id: 1, marketplace_segment_id: 1 },
    #   { unique: false }
    # )
    # index(
    #   { enrolled_member_hbx_id: 1, exchange_assigned_policy_id: 1, hbx_qhp_id: 1, marketplace_segment_id: 1 },
    #   { unique: true }
    # )

    def to_hash
      values = self.serializable_hash.deep_symbolize_keys.merge(id: id.to_s)
      AcaEntities::Ledger::Contracts::UserFeeReportItemContract.new.call(values).to_h
    end

    alias to_h to_hash

    private

    def passes_contract_validation
      result = AcaEntities::Ledger::Contracts::UserFeeReportItemContract.new.call(self.to_hash)
      errors.add(:base, result.errors) if result.failure?
    end
  end
end
