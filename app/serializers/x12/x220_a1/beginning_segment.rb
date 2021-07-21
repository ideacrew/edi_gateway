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

      # rubocop:disable Style/StringConcatenation
      # rubocop:disable Style/SlicingWithRange
      def parse_date_time_and_location
        return nil if transaction_set_creation_date.blank?
        return nil if transaction_set_creation_time.blank?
        date_segments = [
          transaction_set_creation_date[0, 4].to_i,
          transaction_set_creation_date[4, 2].to_i,
          transaction_set_creation_date[6, 2].to_i
        ]
        time_segments = [
          transaction_set_creation_time[0, 2].to_i,
          transaction_set_creation_time[2, 2].to_i
        ]
        second_parts = transaction_set_creation_time[4..-1]
        seconds =
          if second_parts.blank?
            0
          elsif second_parts.length > 2
            (second_parts[0, 2] + "." + second_parts[2..-1]).to_f
          else
            second_parts.to_i
          end
        dt_args = date_segments + time_segments + [seconds]
        build_time_value(dt_args)
      end
      # rubocop:enable Style/StringConcatenation
      # rubocop:enable Style/SlicingWithRange

      def build_time_value(t_args)
        time_strategy = pick_time_strategy
        if time_strategy.first == :offset
          DateTime.new(*(t_args + [time_strategy.last]))
        else
          ActiveSupport::TimeZone[time_strategy.last].local(*t_args).to_datetime
        end
      end

      def pick_time_strategy
        {
          "ED" => [:offset, '-04:00'],
          "ES" => [:offset, '-05:00'],
          "ET" => [:zone, "Eastern Time (US & Canada)"],
          "UT" => [:offset, "+00:00"]
        }.fetch(time_zone_code, [:offset, "+00:00"])
      end
    end
  end
end