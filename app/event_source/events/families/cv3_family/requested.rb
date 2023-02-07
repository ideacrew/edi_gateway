# frozen_string_literal: true

module Events
  module Families
    module Cv3Family
      class Requested < EventSource::Event
        publisher_path 'publishers.families.cv3_family_requested_publisher'
      end
    end
  end
end
