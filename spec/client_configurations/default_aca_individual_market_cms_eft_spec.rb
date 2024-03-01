# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'default aca_individual_market namespace client specific configurations' do
  describe 'cms_eft_serverless' do
    context 'for default value' do
      it 'returns default value of false' do
        expect(
          EdiGatewayRegistry.feature_enabled?(:cms_eft_serverless)
        ).to be_falsey
      end
    end
  end
end
