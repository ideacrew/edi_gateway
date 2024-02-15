# frozen_string_literal: true

module Protocols
  module X12
    class TransactionSetEnrollment < Protocols::X12::TransactionSetHeader
      # ASC X12 834 Benefit Enrollment Transaction
      field :bgn01, as: :ts_purpose_code, type: String
      field :bgn02, as: :ts_reference_number, type: String
      field :bgn03, as: :ts_date, type: String
      field :bgn04, as: :ts_time, type: String
      field :bgn05, as: :ts_time_code, type: String, default: "UT"
      field :bgn06, as: :ts_reference_id, type: String
      field :bgn08, as: :ts_action_code, type: String

      field :sponsor_code, as: :loop_1000a_n103, type: String
      field :sponsor_id, as: :loop_1000a_n104, type: String
      field :payer_code, as: :loop_1000b_n103, type: String
      field :payer_id, as: :loop_1000b_n104, type: String

      field :broker_code, as: :loop_1000c_n103, type: String
      field :broker_id, as: :loop_1000c_n104, type: String
      field :tpa_code, as: :loop_1000c_n103_tpa, type: String
      field :tpa_id, as: :loop_1000c_n104_tpa, type: String

      field :maint_type, as: :loop_2000_ins03, type: String
      field :maint_type, as: :loop_2000_ins03, type: String

      field :error_list, type: Array
      field :submitted_at, type: DateTime

      # field :eg_id, as: :enrollment_group_id, String
      index({ "bgn01" => 1 })
      index({ "bgn02" => 1 })
      index({ "bgn06" => 1 })
      index({ "bgn08" => 1 })
      index({ "submitted_at" => 1 })
      index({ "submitted_at" => 1, "policy_id" => 1 })
      index({ "policy_id" => 1 })

      belongs_to :policy
      # belongs_to :employer
    end
  end
end
