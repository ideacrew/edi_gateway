# frozen_string_literal: true

module Events
  module UserFees
    module EnrollmentAdds
      # Notification that one or more {UserFees::Policy Policies} were added to a {UserFees::Customer Customer}
      class PoliciesAdded < EventSource::Event
        publisher_path 'publishers.user_fees.enrollment_adds_publisher'
      end
    end
  end
end
