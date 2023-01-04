# frozen_string_literal: true

require 'shared_examples/cv3_family'

RSpec.describe InsurancePolicies::AcaIndividuals::EnrolledMembers::Create do
  subject { described_class.new }
  include_context 'cv3_family'

  let!(:hbx_enrollment) { hbx_enrollments.first }

  let!(:persisted_enrollment) do
    FactoryBot.create(:enrollment, hbx_id: hbx_enrollment[:hbx_id])
  end
  let!(:hbx_enrollment_members) { hbx_enrollments.first[:hbx_enrollment_members] }

  let!(:policy) do
    FactoryBot.create(:policy)
  end

  let!(:people) do
    hbx_enrollment_members.collect do |member|
      FactoryBot.create(:person, hbx_member_id: member[:family_member_reference][:family_member_hbx_id],
                                 authority_member_id: member[:family_member_reference][:family_member_hbx_id])
    end
  end

  let!(:enrollees) do
    hbx_enrollment_members.collect do |member|
      FactoryBot.create(:enrollee, policy: policy, m_id: member[:family_member_reference][:family_member_hbx_id])
    end
  end

  let!(:subscriber_params) do
    hbx_enrollment_members.first.merge!(person_hash: people.first.as_json.deep_symbolize_keys, enrollment_hash: hbx_enrollment.as_json.deep_symbolize_keys, glue_enrollee: enrollees.first,
                                        type: "subscriber")
  end

  context 'with invalid payload' do
    it "return failure" do
      result = subject.call({})
      expect(result.failure?).to be_truthy
    end
  end

  context 'with valid payload' do
    before do
      @result = subject.call(subscriber_params)
    end

    it "return success" do
      expect(@result.success?).to be_truthy
    end

    it "return hash" do
      expect(@result.success.class).to be Hash
    end

    it "should have subscriber" do
      expect(@result.success[:subscriber].present?).to be_truthy
    end
  end
end
