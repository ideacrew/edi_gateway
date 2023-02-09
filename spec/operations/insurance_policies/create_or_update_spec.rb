# frozen_string_literal: true

require 'rails_helper'

RSpec.describe InsurancePolicies::CreateOrUpdate, dbclean: :after_each do
  subject { described_class.new.call(input_params) }

  describe '#call' do
    context 'with valid input params' do
      let(:input_params) { {} }

      it 'returns a success with a message' do
        expect(
          subject.success
        ).to eq('Successfully processed event: enroll.families.found_by')
      end
    end

    # context 'with invalid input params' do
    # end
  end
end
