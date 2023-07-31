# frozen_string_literal: true

module Protocols
  module X12
    # Represents header information for ST/SE level transactions.
    class TransactionSetHeader
      include Mongoid::Document
      include Mongoid::Timestamps
      store_in client: :edidb

      field :st01, as: :ts_id, type: String
      field :st02, as: :ts_control_number, type: String
      field :st03, as: :ts_implementation_convention_reference, type: String

      field :transaction_kind, type: String
      field :aasm_state, type: String
      field :ack_nak_processed_at, type: Time

      # FIX: this should reference self.transmission.isa08
      field :receiver_id, type: String
      index({ receiver_id: 1 })

      index({ st02: 1 })
      index({ aasm_state: 1 })

      belongs_to :carrier, index: true
      belongs_to :transmission, counter_cache: true, index: true, :class_name => "::Protocols::X12::Transmission"

      # Hacks for looking up body.
      field :body, type: String

      def legacy_file
        @legacy_file ||= ::LegacyFile.where({ :filename => "uploads/#{body}" }).first
      end

      def raw_content
        legacy_file&.chunks&.map(&:to_s)&.join
      end

      def transmission_file_name
        transmission&.file_name
      end

      def interchange_control_number
        transmission&.isa13
      end
    end
  end
end
