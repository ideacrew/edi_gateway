# frozen_string_literal: true

module Publishers
  module Families
    module Notices
      module TaxForms
        # Publisher will send request to Polypress to generate catastrophic_notice for ivl_tax 1095a.
        class Catastrophic1095aRequestedPublisher
          include ::EventSource::Publisher[amqp: 'edi_gateway.families.notices.tax_forms.catastrophic1095a']

          register_event 'requested'
        end
      end
    end
  end
end

# ENR 1
# THH1: (50, 48, 16)
# thh2 :(24)
# thh3: (24)

# ENR2
# THH1: (50, 48, 9)
# # thh2 :(24)
# # thh3 :(24)
# # thh4 :(24)

# [[50, 48,16], [24], [24]]
# enr.tax_households.map(&:tax_household_members).map(&:person_id)

# [[50,48,9], [24], [24], [24]]
#   thhs = []

# enr.tax_households.each do
# enr1.tax_household <=> enr2.tax_housheold.tax_household_members

# enr1
