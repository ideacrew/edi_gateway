# frozen_string_literal: true

module Publishers
  module UserFees
    # Publish {UserFees::Customer} events
    class CustomerPublisher
      include ::EventSource::Publisher[amqp: 'edi_gateway.user_fees.customer.events']

      register_event 'customer_created'
      register_event 'customer_updated'
    end
  end
end
