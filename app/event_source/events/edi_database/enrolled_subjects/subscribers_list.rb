# frozen_string_literal: true

module Events
  module EdiDatabase
    module EnrolledSubjects
      # SubscribersListRequested will register event publisher for Glue
      class SubscribersList < EventSource::Event
        publisher_path 'publishers.edi_database.subscribers_list_publisher'
      end
    end
  end
end