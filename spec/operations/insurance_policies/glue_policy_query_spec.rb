# frozen_string_literal: true

require 'shared_examples/cv3_family'

RSpec.describe InsurancePolicies::GluePolicyQuery, db_clean: :before do
  before do
    DatabaseCleaner.clean
  end

  context 'group_by_subscriber_query' do
    let!(:policy) do
      FactoryBot.create(:policy, id: SecureRandom.uuid, created_at: DateTime.now,
                                 updated_at: DateTime.now, eg_id: "12345")
    end

    let!(:enrollees) do
      FactoryBot.create(:enrollee, policy: policy, m_id: '1030800', rel_code: 'self')
    end

    context 'when no responsible party id is set' do
      it 'returns policies which has no rp set' do
        start_time = policy.created_at
        end_time = policy.created_at + 10.minutes
        result = described_class.new(start_time, end_time).group_by_subscriber_query
        expect(result.first['enrolled_policies']).to include(policy.eg_id)
      end
    end

    context 'when responsible party id is set to nil' do
      it 'returns policies which has rp set to nil' do
        policy.update_attributes(responsible_party_id: nil)
        start_time = policy.created_at
        end_time = policy.created_at + 10.minutes
        result = described_class.new(start_time, end_time).group_by_subscriber_query
        expect(result.first['enrolled_policies']).to include(policy.eg_id)
      end
    end

    context 'when responsible party id is set' do
      it 'not returns policies which has rp set' do
        policy.update_attributes(responsible_party_id: BSON::ObjectId.new)
        start_time = policy.created_at
        end_time = policy.created_at + 10.minutes
        result = described_class.new(start_time, end_time).group_by_subscriber_query
        expect(result.count.zero?).to be_truthy
      end
    end
  end

  context 'group_by_responsible_party_query' do
    let!(:policy) do
      FactoryBot.create(:policy, id: SecureRandom.uuid, created_at: DateTime.now,
                                 updated_at: DateTime.now, eg_id: "12345")
    end

    let!(:enrollees) do
      FactoryBot.create(:enrollee, policy: policy, m_id: '1030800', rel_code: 'self')
    end

    context 'when no responsible party id is set' do
      it 'not return any policies which has no rp set' do
        start_time = policy.created_at
        end_time = policy.created_at + 10.minutes
        result = described_class.new(start_time, end_time).group_by_responsible_party_query
        expect(result.count.zero?).to be_truthy
      end
    end

    context 'when responsible party id is set to nil' do
      it 'not return any policies which has rp set to nil' do
        policy.update_attributes(responsible_party_id: nil)
        start_time = policy.created_at
        end_time = policy.created_at + 10.minutes
        result = described_class.new(start_time, end_time).group_by_responsible_party_query
        expect(result.count.zero?).to be_truthy
      end
    end

    context 'when responsible party id is set' do
      it 'not returns policies which has rp set' do
        policy.update_attributes(responsible_party_id: BSON::ObjectId.new)
        start_time = policy.created_at
        end_time = policy.created_at + 10.minutes
        result = described_class.new(start_time, end_time).group_by_responsible_party_query
        expect(result.first['enrolled_policies']).to include(policy.eg_id)
      end
    end
  end
end
