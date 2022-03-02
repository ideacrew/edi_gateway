# frozen_string_literal: true

module Publishers
  module UserFees
    # Publish {UserFees::Enrollment} events
    class EnrollmentPublisher
      include ::EventSource::Publisher[amqp: 'edi_gateway.user_fees.enrollment.events']

      register_event 'enrollment_added'
      register_event 'enrollment_terminated'
      register_event 'enrollment_reinstated'
      register_event 'enrollment_changed'
    end
  end
end
