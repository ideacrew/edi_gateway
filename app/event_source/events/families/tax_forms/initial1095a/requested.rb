# frozen_string_literal: true

module Events
  module Families
    module TaxForms
      module Initial1095a
        # This class will register event 'initial1095a_payload_generated_publisher'
        class Generated < EventSource::Event
          publisher_path 'publishers.families.tax_forms.initial1095a_payload_generated_publisher'
        end
      end
    end
  end
end
