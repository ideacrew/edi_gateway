# frozen_string_literal: true

module Events
  module InsurancePolicies
    # This class has publisher path to register event
    class Posted < EventSource::Event
      publisher_path 'publishers.insurance_policies.posted_publisher'
    end
  end
end
