# frozen_string_literal: true

module Events
  module EdiDatabase
    module IrsGroups
      # Notification that a {EdiDatabase::IrsGroups::PolicyAndInsuranceAgreementCreated} was requested
      class PolicyAndInsuranceAgreementCreated < EventSource::Event
        publisher_path 'publishers.edi_database.irs_groups.irs_group_publisher'
      end
    end
  end
end
