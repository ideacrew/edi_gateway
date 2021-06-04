# frozen_string_literal: true

module X12
  module X220A1
    # BGN segment.
    class BeginningSegment
      include HappyMapper
      register_namespace 'x12', 'urn:x12:schemas:005:010:834A1A1:BenefitEnrollmentAndMaintenance'

      tag "BGN_BeginningSegment"
      namespace 'x12'

      element :transaction_set_purpose_code, String, tag: "BGN01__TransactionSetPurposeCode", namespace: "x12"
      element :transaction_set_reference_number, String, tag: "BGN02__TransactionSetReferenceNumber", namespace: "x12"
      element :transaction_set_creation_date, String, tag: "BGN03__TransactionSetCreationDate", namespace: "x12"
      element :transaction_set_creation_time, String, tag: "BGN04__TransactionSetCreationTime", namespace: "x12"
      element :time_zone_code, String, tag: "BGN05__TimeZoneCode", namespace: "x12"
      element :reference_identification, String, tag: "BGN06__OriginalTransactionSetReferenceNumber", namespace: "x12"
      element :action_code, String, tag: "BGN08__ActionCode", namespace: "x12"

      def to_domain_parameters
        optional_params = {}
        optional_params[:reference_identification] = reference_identification unless reference_identification.blank?
        {
          transaction_set_purpose_code: transaction_set_purpose_code,
          transaction_set_reference_number: transaction_set_reference_number,
          action_code: action_code,
          transaction_set_timestamp: parse_date_time_and_location
        }.merge(optional_params)
      end

      protected

      def parse_date_time_and_location
        nil
      end
    end
  end
end