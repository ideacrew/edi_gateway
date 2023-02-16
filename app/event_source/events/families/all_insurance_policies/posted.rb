# frozen_string_literal: true

module Events
  module Families
    module AllInsurancePolicies
      # This class has publisher path to register event
      class Posted < EventSource::Event
        publisher_path 'publishers.families.all_insurance_policies.posted_publisher'
      end
    end
  end
end
