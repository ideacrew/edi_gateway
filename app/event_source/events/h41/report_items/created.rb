# frozen_string_literal: true

module Events
  module H41
    module ReportItems
      # This class will register event 'h41_payload_requested_publisher'
      class Created < EventSource::Event
        publisher_path 'publishers.H41.transmissions_created'
      end
    end
  end
end
