# frozen_string_literal: true

module Events
  module UserFees
    module EnrollmentTerminations
      # Notification that {UserFees::InsuranceCoverage InsuranceCoverage} was terminated for a {UserFees::Customer Customer}
      class EnrollmentTerminated < EventSource::Event
        publisher_path 'publishers.user_fees.enrollment_terminations_publisher'
      end
    end
  end
end
