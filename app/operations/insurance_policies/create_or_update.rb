# frozen_string_literal: true

module InsurancePolicies
  # Process 'enroll.families.found_by' event
  class CreateOrUpdate
    include Dry::Monads[:result, :do]
    # include EventSource::Command

    # TODO: Implement business logic
    def call(_params)
      Success('Successfully processed event: enroll.families.found_by')
    end
  end
end
