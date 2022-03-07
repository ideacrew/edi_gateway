# frozen_string_literal: true

module Publishers
  module UserFees
    # Publish {UserFees::Enrollment} events
    class EnrollmentAddsPublisher
      include ::EventSource::Publisher[amqp: 'edi_gateway.user_fees.enrollment_adds.events']

      register_event 'enrolled_members_added'
      register_event 'initial_enrollment_added'
      register_event 'policies_added'
      register_event 'tax_housholds_added'
    end
  end
end
