# frozen_string_literal: true

module Events
  module Families
    module Notices
      module TaxForms
        module Catastrophic1095a
          # This class will register event 'catastrophic_notice_generation_requested'
          class Requested < EventSource::Event
            publisher_path 'publishers.families.notices.tax_forms.catastrophic1095a_requested_publisher'
          end
        end
      end
    end
  end
end

# Events::Families::Notices::IvlTax::CatastrophicNoticeGeneration
