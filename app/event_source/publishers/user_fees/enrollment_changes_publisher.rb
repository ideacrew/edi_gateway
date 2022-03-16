# frozen_string_literal: true

module Publishers
  module UserFees
    # Publish {Events::UserFees::EnrollmentChanges} events
    class EnrollmentChangesPublisher
      include ::EventSource::Publisher[amqp: 'edi_gateway.user_fees.enrollment_changes.events']

      register_event 'enrolled_members_added'
      register_event 'enrolled_members_dropped'
      register_event 'enrolled_members_identifiers_changed'
      register_event 'enrolled_members_effective_date_changed'
      register_event 'enrolled_members_tobacco_rating_changed'
      register_event 'enrolled_members_premium_changed'
      register_event 'tax_household_aptc_or_csr_changed'
      register_event 'tax_household_effective_date_changed'
      register_event 'policy_rating_area_changed'
      register_event 'policy_effective_date_changed'
    end
  end
end
