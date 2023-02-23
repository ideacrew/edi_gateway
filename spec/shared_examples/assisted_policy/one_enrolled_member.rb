# frozen_string_literal: true

require 'shared_examples/cv3_family'

RSpec.shared_context 'one_enrolled_member' do
  include_context 'cv3_family'

  let!(:hbx_enrollment_1) { hbx_enrollments.first }
  let!(:hbx_enrollment_2) { hbx_enrollments.last }
  let!(:hbx_enrollment_members) { hbx_enrollments.first[:hbx_enrollment_members] }
  let!(:people) do
    hbx_enrollment_members.collect do |member|
      hbx_id = member[:family_member_reference][:family_member_hbx_id]
      glue_person = FactoryBot.create(:person, hbx_member_id: hbx_id,
                                               authority_member_id: hbx_id,
                                               name_first: person_name[:first_name],
                                               name_last: person_name[:last_name])

      glue_person.members.first.update_attributes(ssn: "123456789")
      glue_person.addresses.first.update_attributes(address_1: addresses.first[:address_1])
      glue_person.emails.first.update_attributes(email_address: emails[0][:address])
      name = FactoryBot.build(:people_person_name, first_name: person_name[:first_name],
                                                   last_name: person_name[:last_name])
      people_person = FactoryBot.create(:people_person, hbx_id: hbx_id, name: name)
      people_person.addresses.first.update_attributes(address_1: addresses.first[:address_1])
      people_person.emails.first.update_attributes(address: emails[0][:address])
      people_person
    end
  end
  let!(:start_on) { Date.new(2023, 1, 1) }

  let!(:subscriber_person) { People::Person.all.first }
  let!(:irs_group) { FactoryBot.create(:irs_group) }
  let!(:enrollment_1) do
    FactoryBot.create(:enrollment, start_on: start_on, effectuated_on: start_on,
                                   hbx_id: hbx_enrollment_1[:hbx_id])
  end
  let!(:enrollment_2) do
    FactoryBot.create(:enrollment, start_on: start_on, effectuated_on: start_on,
                                   hbx_id: hbx_enrollment_2[:hbx_id], aasm_state: "coverage_canceled")
  end
  let!(:irs_group) do
    irs_group = enrollment_1.insurance_policy.irs_group
    irs_group.family_hbx_assigned_id = "12345"
    irs_group.start_on = start_on.year
    irs_group.save!
    irs_group
  end

  let!(:subscriber_1) do
    enrolled_member = FactoryBot.build(:enrolled_member)
    enrolled_member.person_id = subscriber_person.id
    enrolled_member.relation_with_primary = "self"
    enrollment_1.subscriber = enrolled_member
    enrolled_member.save
    enrolled_member
  end

  let!(:subscriber_2) do
    enrolled_member = FactoryBot.build(:enrolled_member)
    enrolled_member.person_id = subscriber_person.id
    enrolled_member.relation_with_primary = "self"
    enrollment_2.subscriber = enrolled_member
    enrolled_member.save
    enrolled_member
  end

  let!(:premium_schedule_1) { FactoryBot.create(:premium_schedule, enrolled_member: subscriber_1) }
  let!(:premium_schedule_2) { FactoryBot.create(:premium_schedule, enrolled_member: subscriber_2) }

  let!(:insurance_policy_1) do
    insurance_policy = enrollment_1.insurance_policy
    insurance_policy.irs_group_id = irs_group.id
    insurance_policy.start_on = start_on
    insurance_policy.policy_id = enrollment_1.hbx_id
    insurance_policy.aasm_state = "submitted"
    insurance_policy.carrier_policy_id = "1234"
    insurance_policy.save!
    insurance_policy
  end

  let!(:insurance_policy_2) do
    insurance_policy = enrollment_2.insurance_policy
    insurance_policy.irs_group_id = irs_group.id
    insurance_policy.start_on = start_on
    insurance_policy.policy_id = enrollment_2.hbx_id
    insurance_policy.aasm_state = "canceled"
    insurance_policy.carrier_policy_id = "1234"
    insurance_policy.save!
    insurance_policy
  end

  let!(:insurance_agreement_1) do
    insurance_agreement = insurance_policy_1.insurance_agreement
    insurance_agreement.plan_year = enrollment_1.start_on.year
    insurance_agreement.contract_holder = subscriber_person
    insurance_agreement.save!
    insurance_agreement
  end

  let!(:insurance_agreement_2) do
    insurance_agreement = insurance_policy_2.insurance_agreement
    insurance_agreement.plan_year = enrollment_2.start_on.year
    insurance_agreement.contract_holder = subscriber_person
    insurance_agreement.save!
    insurance_agreement
  end

  let!(:insurance_product) { insurance_policy_1.insurance_product }
  let!(:insurance_provider) do
    insurance_provider = insurance_agreement_1.insurance_provider
    insurance_provider.insurance_products << insurance_product
    insurance_provider.save!
    insurance_provider
  end

  let!(:tax_household_group) { FactoryBot.create(:tax_household_group, irs_group: irs_group) }
  let!(:tax_household) do
    FactoryBot.create(:tax_household, hbx_id: thh_hash[:hbx_id], tax_household_group: tax_household_group, max_aptc: 100.0)
  end
  let!(:tax_household_member) do
    FactoryBot.create(:tax_household_member, tax_household: tax_household, person: subscriber_person)
  end

  let!(:enr_thh_1) do
    FactoryBot.create(:enrollments_tax_households, enrollment: enrollment_1, tax_household: tax_household, applied_aptc: 50.0,
                                                   household_benchmark_ehb_premium: 500.0)
  end
  let!(:enr_thh_2) do
    FactoryBot.create(:enrollments_tax_households, enrollment: enrollment_2, tax_household: tax_household, applied_aptc: 50.0,
                                                   household_benchmark_ehb_premium: 500.0)
  end
  let!(:enr_members_thhm_1) { FactoryBot.create(:enrolled_members_tax_household_members, enrollments_tax_households: enr_thh_1) }
  let!(:enr_members_thhm_2) { FactoryBot.create(:enrolled_members_tax_household_members, enrollments_tax_households: enr_thh_2) }

  let!(:thh_hash) { tax_households.first }

  let!(:policy) { FactoryBot.create(:policy) }

  let!(:enrollees) do
    hbx_enrollment_members.collect do |member|
      FactoryBot.create(:enrollee, policy: policy, m_id: member[:family_member_reference][:family_member_hbx_id])
    end
  end
end
