# frozen_string_literal: true

module Events
  module Gdb
    module EnrolledSubjects
      # SubscribersListRequested will register event publisher for Glue
      class SubscribersList < EventSource::Event
        publisher_path 'publishers.gdb.subscribers_list_publisher'
      end
    end
  end
end