# frozen_string_literal: true

require 'rails_helper'

RSpec.describe InsurancePolicies::Refresh, dbclean: :after_each do
  subject { described_class.new.call(input_params) }

  describe '#call' do
    context 'with valid input params' do
      let(:input_params) { { 'refresh_period' => '02/07/2023 09:51..02/07/2023 18:51' } }

      it 'returns a success with a message' do
        expect(
          subject.success
        ).to eq('Successfully processed event: enroll.insurance_policies.refresh_requested')
      end
    end

    # context 'with invalid input params' do
    # end
  end
end
