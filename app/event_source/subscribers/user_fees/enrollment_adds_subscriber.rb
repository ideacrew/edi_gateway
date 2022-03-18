# frozen_string_literal: true

module Subscribers
  module UserFees
    # Subscriber will receive event detailing a new customer/enrollment
    class EnrollmentAddsSubscriber
      include ::EventSource::Subscriber[amqp: 'edi_gateway.user_fees.enrollment_adds']

      subscribe(:on_policies_added) { |delivery_info, _metadata, response| ack(delivery_info.delivery_tag) }

      subscribe(:on_tax_households_added) { |delivery_info, _metadata, response| ack(delivery_info.delivery_tag) }

      subscribe(:on_initial_enrollment_added) do |delivery_info, _metadata, response|
        subscriber_logger = subscriber_logger_for(:on_initial_enrollment_added)
        payload = JSON.parse(response, symbolize_names: true)
        subscriber_logger.info "EnrollmentAddsSubscriber, response: #{payload}"

        # Add subscriber operations below this line
        update_user_fees(payload)

        subscriber_logger.info "EnrollmentAddsSubscriber, ack: #{payload}"
        ack(delivery_info.delivery_tag)
      rescue StandardError, SystemStackError => e
        subscriber_logger.info "EnrollmentAddsSubscriber, payload: #{payload}, error message: #{e.message}, backtrace: #{e.backtrace}"

        subscriber_logger.info "EnrollmentAddsSubscriber, ack: #{payload}"
        ack(delivery_info.delivery_tag)
      end

      def update_user_fees(payload)
        binding.pry
      end

      private

      def subscriber_logger_for(event)
        Logger.new("#{Rails.root}/log/#{event}_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")
      end
    end
  end
end
