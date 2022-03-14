# frozen_string_literal: true

module Events
  module UserFees
    module EnrollmentAdds
      # Notification that a new {UserFees::Customer Customer} added {UserFees::InsuranceCoverage InsuranceCoverage}
      class InitialEnrollmentAdded < EventSource::Event
        publisher_path 'publishers.user_fees.enrollment_adds_publisher'
      end
    end
  end
end
