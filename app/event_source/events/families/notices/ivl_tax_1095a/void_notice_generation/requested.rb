# frozen_string_literal: true

module Events
  module Families
    module Notices
      module IvlTax1095A
        module VoidNoticeGeneration
        # This class will register event 'void_notice_generation_requested'
          class Requested < EventSource::Event
            publisher_path 'publishers.families.notices.ivl_tax_1095a.void_notice_generation_requested_publisher'

          end
        end
      end
    end
  end
end
