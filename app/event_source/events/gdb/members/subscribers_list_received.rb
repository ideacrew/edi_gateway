# frozen_string_literal: true

module Events
  module Gdb
    module Members
      # SubscribersListRequested will register event publisher for Glue
      class SubscribersListReceived < EventSource::Event
        publisher_path 'publishers.gdb.members.subscribers_list_requested_publisher'

      end
    end
  end
end