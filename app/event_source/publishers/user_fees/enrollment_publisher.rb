# frozen_string_literal: true

module Publishers
  module UserFees
    # Publish {UserFees::Enrollment} events
    class EnrollmentPublisher
      include ::EventSource::Publisher[amqp: 'edi_gateway.user_fees.enrollment.events']

      register_event 'enrollment_created'
      register_event 'enrollment_updated'
    end
  end
end
