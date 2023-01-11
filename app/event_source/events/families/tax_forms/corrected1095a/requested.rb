# frozen_string_literal: true

module Events
  module Families
    module TaxForms
      module Corrected1095a
        # This class will register event 'corrected_notice_generation_requested'
        class Generated < EventSource::Event
          publisher_path 'publishers.families.tax_forms.corrected1095a_payload_generated_publisher'
        end
      end
    end
  end
end
