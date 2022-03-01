# frozen_string_literal: true

module Events
  module UserFees
    module Enrollments
      # This class will register event
      class EnrollmentCreated < EventSource::Event
        publisher_path 'publishers.user_fees.enrollment_publisher'
      end
    end
  end
end
