# frozen_string_literal: true

require 'securerandom'
module Eventable
  def publish_events(events)
    Success(events.each { |event| event.success.publish })
  rescue StandardError => e
    Failure[:event_publish_error, params: customer_new_state, error: e.to_s, backtrace: e.backtrace]
  end

  def build_event(event_name, change_set, customer_state, customer_new_state)
    event_namespace = 'events.user_fees.enrollment_adds'
    full_event_name = [event_namespace, event_name].join('.')
    meta = build_meta_content(change_set, customer_new_state)
    attributes = { meta: meta, old_state: { customer: customer_state }, new_state: { customer: customer_new_state } }

    event(full_event_name, attributes: attributes)
  end

  def build_meta_content(change_set, customer_new_state)
    correlation_id = SecureRandom.uuid
    time = DateTime.now
    { correlation_id: correlation_id, time: time, customer_hbx_id: customer_new_state[:hbx_id], change_set: change_set }
  end
end
