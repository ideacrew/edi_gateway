# frozen_string_literal: true

module Publishers
  module UserFees
    # Publish {UserFees::Account} events
    class AccountPublisher
      include ::EventSource::Publisher[amqp: 'edi_gateway.user_fees.account.events']

      register_event 'account_created'
      register_event 'account_updated'
    end
  end
end
