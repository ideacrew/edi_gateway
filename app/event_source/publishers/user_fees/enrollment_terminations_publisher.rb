# frozen_string_literal: true

module Publishers
  module UserFees
    # Publish {Events::UserFees::EnrollmentTerminations} events
    class EnrollmentTerminationsPublisher
      send(:include, ::EventSource::Publisher[amqp: 'edi_gateway.user_fees.enrollment_terminations'])

      register_event 'enrollment_terminated'
      register_event 'policies_terminated'
      register_event 'tax_households_terminated'
    end
  end
end
