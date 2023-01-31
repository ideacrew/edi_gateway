# frozen_string_literal: true

module Publishers
  module H41
    class ReportItemsPublisher
      send(:include, ::EventSource::Publisher[amqp: 'edi_gateway.h41.report_items'])

      register_event 'created'
    end
  end
end
