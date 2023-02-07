# frozen_string_literal: true

require 'shared_examples/cv3_family'

RSpec.describe InsurancePolicies::AcaIndividuals::Enrollments::Find do
  subject { described_class.new }
  include_context 'cv3_family'

  let!(:enrollment) do
    FactoryBot.create(:enrollment)
  end

  let(:params) { { scope_name: :by_hbx_id, criterion: enrollment.hbx_id } }

  context 'with invalid payload' do
    it "return failure" do
      result = subject.call({})
      expect(result.failure?).to be_truthy
    end
  end

  context 'with valid payload' do
    before do
      @result = subject.call(params)
    end

    it "return success" do
      expect(@result.success?).to be_truthy
    end

    it "return hash" do
      expect(@result.success.class).to be Hash
    end

    it "should have hbx_id" do
      expect(@result.success[:hbx_id]).to eq enrollment.hbx_id
    end
  end
end
