# frozen_string_literal: true

module Events
  module EdiDatabase
    module EnrolledSubjects
      # SubscriberCoverageInformation will register event publisher for Glue for coverage information
      class SubscriberCoverageInformation < EventSource::Event
        publisher_path 'publishers.edi_database.subscriber_coverage_information_publisher'
      end
    end
  end
end