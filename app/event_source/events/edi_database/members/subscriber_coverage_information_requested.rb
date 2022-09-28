# frozen_string_literal: true

module Events
  module EdiDatabase
    module Members
      # SubscriberCoverageInformationRequested will register event publisher for Glue
      class SubscriberCoverageInformationRequested < EventSource::Event
        publisher_path 'publishers.edi_database.members.subscriber_coverage_information_publisher'
      end
    end
  end
end