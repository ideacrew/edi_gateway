# frozen_string_literal: true

module Protocols
  module X12
    # Represents a set of transactions.
    class Transmission
      include Mongoid::Document
      include Mongoid::Timestamps

      store_in client: :edidb

      field :isa06, as: :ic_sender_id, type: String
      field :isa08, as: :ic_receiver_id, type: String
      field :isa09, as: :ic_date, type: String
      field :isa10, as: :ic_time, type: String
      field :isa12, as: :ic_number, type: String
      field :isa13, as: :ic_control_number, type: String
      field :isa15, as: :ic_usage_indicator, type: String

      field :gs01, as: :fg_id_code, type: String, default: "BE"
      field :gs02, as: :fg_application_senders_code, type: String
      field :gs03, as: :fg_application_receivers_code, type: String
      field :gs04, as: :fg_date, type: String
      field :gs05, as: :fg_time, type: String
      field :gs06, as: :fg_control_number, type: String
      field :gs07, as: :fg_responsible_agency_code, type: String, default: "X"
      field :gs08, as: :fg_x12_standards_reference_code, type: String

      field :file_name, type: String
      field :status, type: String, default: "transmitted"
      field :submitted_at, type: DateTime

      field :aasm_state, type: String
      field :ack_nak_processed_at, type: DateTime

      index({ "isa06" => 1 })
      index({ "isa08" => 1 })
      index({ "isa13" => 1 })
      index({ "isa08" => 1, "gs01" => 1, "gs06" => 1, "gs08" => 1 })
      index({ "isa08" => 1, "isa13" => 1 })

      index({ "gs02" => 1 })
      index({ "gs03" => 1 })

      index({ "aasm_state" => 1 })

      before_create :parse_submitted_at

      def sender
        TradingPartner.elem_match(trading_profiles: { profile_code: ic_sender_id.strip }).first
      end

      def receiver
        TradingPartner.elem_match(trading_profiles: { profile_code: ic_receiver_id.strip }).first
      end

      has_many :transaction_set_enrollments, :class_name => "::Protocols::X12::TransactionSetEnrollment"
      # has_many :transaction_set_premium_payments, :class_name => "Protocols::X12::TransactionSetPremiumPayment"
    end
  end
end
