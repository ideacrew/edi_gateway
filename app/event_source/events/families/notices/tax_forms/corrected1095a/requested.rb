# frozen_string_literal: true

module Events
  module Families
    module Notices
      module TaxForms
        module Corrected1095a
          # This class will register event 'corrected_notice_generation_requested'
          class Requested < EventSource::Event
            publisher_path 'publishers.families.notices.tax_forms.corrected1095a_requested_publisher'
          end
        end
      end
    end
  end
end
