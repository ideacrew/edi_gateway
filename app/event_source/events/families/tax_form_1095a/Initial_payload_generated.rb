# frozen_string_literal: true

module Events
  module Families
    module TaxForm1095a
      # This class will register event 'catastrophic1095a_payload_generated_publisher'
      class InitialPayloadGenerated < EventSource::Event
        publisher_path 'publishers.families.notices.tax_form1095a_payload_generated_publisher'
      end
    end
  end
end

# Events::Families::Notices::IvlTax::CatastrophicNoticeGeneration
