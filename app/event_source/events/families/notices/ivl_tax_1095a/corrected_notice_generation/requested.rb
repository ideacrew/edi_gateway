# frozen_string_literal: true

module Events
  module Families
    module Notices
      module IvlTax1095A
        module CorrectedNoticeGeneration
        # This class will register event 'corrected_notice_generation_requested'
          class Requested < EventSource::Event
            publisher_path 'publishers.families.notices.ivl_tax_1095a.corrected_notice_generation_requested_publisher'

          end
        end
      end
    end
  end
end
