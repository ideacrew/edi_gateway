# frozen_string_literal: true

module Subscribers
  module EdiDatabase
    module Transactions
      # Subscriber will receive a transaction detailing and enrollment create, change, terminate or reinstate
      class GdbTransactionSubscriber
        send(:include, ::EventSource::Subscriber[amqp: 'edi_gateway.edi_database.transactions'])

        subscribe(:on_gdb_transaction_created) do |delivery_info, _metadata, response|
          subscriber_logger = subscriber_logger_for(:on_gdb_transaction_created)
          payload = JSON.parse(response, symbolize_names: true)
          subscriber_logger.info "GdbTransactionSubscriber, response: #{payload}"

          # Add subscriber operations below this line
          update_user_fees(payload)

          subscriber_logger.info "GdbTransactionSubscriber, ack: #{payload}"
          ack(delivery_info.delivery_tag)
        rescue StandardError, SystemStackError => e
          subscriber_logger.info "GdbTransactionSubscriber, payload: #{payload}, error message: #{e.message}, backtrace: #{e.backtrace}"

          subscriber_logger.info "GdbTransactionSubscriber, ack: #{payload}"
          ack(delivery_info.delivery_tag)
        end

        def update_user_fees(payload); end

        private

        def subscriber_logger_for(event)
          Logger.new("#{Rails.root}/log/#{event}_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")
        end
      end
    end
  end
end
