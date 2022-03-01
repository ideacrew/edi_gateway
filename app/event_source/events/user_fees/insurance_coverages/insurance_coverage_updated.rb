# frozen_string_literal: true

module Events
  module UserFees
    module InsuranceCoverages
      # This class will register event
      class InsuranceCoverageUpdated < EventSource::Event
        publisher_path 'publishers.user_fees.insurance_coverage_publisher'
      end
    end
  end
end
