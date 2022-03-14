# frozen_string_literal: true

module Publishers
  module UserFees
    # Publish {UserFees::Enrollment} events
    class EnrollmentTerminationsPublisher
      include ::EventSource::Publisher[amqp: 'edi_gateway.user_fees.enrollment_terminations.events']

      register_event 'enrollment_terminated'
      register_event 'policies_terminated'
      register_event 'tax_housholds_terminated'
    end
  end
end
