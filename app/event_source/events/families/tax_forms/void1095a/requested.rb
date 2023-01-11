# frozen_string_literal: true

module Events
  module Families
    module TaxForms
      module Void1095a
        # This class will register event 'void_notice_generation_requested'
        class Generated < EventSource::Event
          publisher_path 'publishers.families.tax_forms.void1095a_payload_generated_publisher'
        end
      end
    end
  end
end
