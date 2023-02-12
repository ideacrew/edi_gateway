# frozen_string_literal: true

module Subscribers
  module DataStores
    # Subscriber will receive a contract holder subject edidb update request
    class ContractHolderSubjectSubscriber
      send(:include, ::EventSource::Subscriber[amqp: 'edi_gateway.data_stores.contract_holder_subjects'])

      subscribe(:on_edidb_update_requested) do |delivery_info, _metadata, response|
        logger(:on_edit_gateway_data_stores_contract_holder_subjects)
        payload = JSON.parse(response, symbolize_names: true)
        log("ContractHolderSubjectSubscriber, response: #{payload}")

        result = DataStores::ContractHolderSubjects::UpdateContractHolderAgreements.new.call(payload)

        if result.success?
          log("ContractHolderSubjectSubscriber; acked for #{routing_key}, payload: #{payload}")
        else
          errors = error_messages(result)
          log(
            "ContractHolderSubjectSubscriber error;
                    due to:#{errors}; for routing_key: #{routing_key}, payload: #{payload}"
          )
        end

        ack(delivery_info.delivery_tag)
      rescue StandardError, SystemStackError => e
        log("ContractHolderSubjectSubscriber, ack, payload: #{payload}, error message: #{e.message}, backtrace: #{e.backtrace}")
        ack(delivery_info.delivery_tag)
      end

      private

      def error_messages(result)
        if result.is_a?(String)
          result
        elsif result.failure.is_a?(String)
          result.failure
        else
          result.failure.errors.to_h
        end
      end

      def log(message)
        @logger.info message
      end

      def logger(event)
        return @logger if defined? @logger

        @logger = Logger.new("#{Rails.root}/log/#{event}_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")
      end
    end
  end
end
