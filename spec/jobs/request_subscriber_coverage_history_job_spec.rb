# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RequestSubscriberCoverageHistoryJob, type: :job do
  describe "#perform_later" do
    it "uploads a backup" do
      ActiveJob::Base.queue_adapter = :test
      expect do
        RequestSubscriberCoverageHistoryJob.perform_later('12345')
      end.to have_enqueued_job
    end
  end
end
