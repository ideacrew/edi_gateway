# frozen_string_literal: true

module Events
  module UserFees
    module EnrollmentAdds
      # This class will register event
      class TaxHouseholdsAdded < EventSource::Event
        publisher_path 'publishers.user_fees.enrollment_adds_publisher'
      end
    end
  end
end
