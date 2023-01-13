module Events
  module InsurancePolicies
    module Tax1095aPayload
      # This class will register event 'tax1095a_payload_requested_publisher'
      class Requested < EventSource::Event
        publisher_path 'publishers.insurance_policies.tax1095a_payload_requested_publisher'
      end
    end
  end
end
