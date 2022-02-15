# frozen_string_literal: true

module Events
  module Gdb
    module EnrolledSubjects
      # SubscriberCoverageInformation will register event publisher for Glue for coverage information
      class SubscriberCoverageInformation < EventSource::Event
        publisher_path 'publishers.gdb.subscriber_coverage_information_publisher'
      end
    end
  end
end