# frozen_string_literal: true

RSpec.describe DataStores::ContractHolderSubject, type: :model, db_clean: :before do
  let(:ch_subject_with_policies) do
    FactoryBot.create(:contract_holder_subject,
                      subscriber_policies: given_subscriber_policy_eg_ids,
                      responsible_party_policies: given_responsible_party_policy_eg_ids)
  end

  let(:ch_subject_without_policies) do
    FactoryBot.create(:contract_holder_subject,
                      subscriber_policies: [],
                      responsible_party_policies: [])
  end

  let(:given_subscriber_policy_eg_ids) { ['100', '101'] }
  let(:given_responsible_party_policy_eg_ids) { ['200', '201'] }

  let(:subscriber_policy_eg_ids) { ['101', '102'] }
  let(:responsible_party_policy_eg_ids) { ['201', '202'] }

  describe '#subscriber_policies=' do
    context 'without current subscriber_policies' do
      let(:output_subscriber_policy_eg_ids) { subscriber_policy_eg_ids }

      it "updates subject's subscriber_policies" do
        ch_subject_without_policies.subscriber_policies = subscriber_policy_eg_ids
        ch_subject_without_policies.save!

        expect(ch_subject_without_policies.subscriber_policies).to eq(output_subscriber_policy_eg_ids)
      end
    end

    context 'with current subscriber_policies' do
      let(:output_subscriber_policy_eg_ids) { (given_subscriber_policy_eg_ids + subscriber_policy_eg_ids).uniq }

      it "updates subject's subscriber_policies" do
        ch_subject_with_policies.subscriber_policies = subscriber_policy_eg_ids
        ch_subject_with_policies.save!

        expect(ch_subject_with_policies.subscriber_policies).to eq(output_subscriber_policy_eg_ids)
      end
    end
  end

  describe '#responsible_party_policies=' do
    context 'without current responsible_party_policies' do
      let(:output_responsible_party_policy_eg_ids) { responsible_party_policy_eg_ids }

      it "updates subject's responsible_party_policies" do
        ch_subject_without_policies.responsible_party_policies = responsible_party_policy_eg_ids
        ch_subject_without_policies.save!

        expect(ch_subject_without_policies.responsible_party_policies).to eq(output_responsible_party_policy_eg_ids)
      end
    end

    context 'with current responsible_party_policies' do
      let(:output_responsible_party_policy_eg_ids) { (given_responsible_party_policy_eg_ids + responsible_party_policy_eg_ids).uniq }

      it "updates subject's responsible_party_policies" do
        ch_subject_with_policies.responsible_party_policies = responsible_party_policy_eg_ids
        ch_subject_with_policies.save!

        expect(ch_subject_with_policies.responsible_party_policies).to eq(output_responsible_party_policy_eg_ids)
      end
    end
  end
end
