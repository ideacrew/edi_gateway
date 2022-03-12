# frozen_string_literal: true

module Events
  module UserFees
    module EnrollmentAdds
      # Event specifying one or more {AcaEntities::Ledger::TaxHousehold} were added to a {AcaEntities::Ledger::Customer}
      class TaxHouseholdsAdded < EventSource::Event
        publisher_path 'publishers.user_fees.enrollment_adds_publisher'
      end
    end
  end
end
