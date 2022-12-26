# frozen_string_literal: true

require 'rails_helper'
require 'securerandom'

RSpec.describe EdiGateway::Types do
  # @deprecated Use {AcaEntities::Types::CorrelationId} instead
  # checks if string adheres to a 8-4-4-4-12 format
  describe 'CorrelationIdKind' do
    let(:uuid_regex) { /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/ }
    let(:correlation_id) { SecureRandom.uuid }

    it 'should generate a random v4 Universally Unique IDentifier (UUID)' do
      expect(correlation_id).to match uuid_regex
      # expect(EdiGateway::Types::CorrelationIdKind[correlation_id]).to be_truthy
    end
  end
end
