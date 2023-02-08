# frozen_string_literal: true

module Events
  module Families
    # This class has publisher path to register event
    class FindByRequested < EventSource::Event
      publisher_path 'publishers.families.find_by_requested_publisher'
    end
  end
end
