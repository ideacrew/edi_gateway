# frozen_string_literal: true

module Publishers
  module UserFees
    # Publish {UserFees::InsuranceCoverage} events
    class InsuranceCoveragePublisher
      include ::EventSource::Publisher[amqp: 'edi_gateway.user_fees.insurance_coverage.events']

      register_event 'insurance_coverage_created'
      register_event 'insurance_coverage_updated'
    end
  end
end
