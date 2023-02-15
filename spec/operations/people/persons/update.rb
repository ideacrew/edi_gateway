# frozen_string_literal: true

require 'shared_examples/cv3_family'

RSpec.describe People::Persons::Update do
  include_context 'cv3_family'

  context "update person record if type is Glue" do
    let!(:edi_gw_person) { FactoryBot.create(:people_person) }
    let!(:glue_person) do
      glue_person = FactoryBot.create(:person, hbx_member_id: edi_gw_person.hbx_id,
                                      authority_member_id: edi_gw_person.hbx_id,
                                      name_first: "first_name",
                                      name_last: "last_name")

      glue_person.members.first.update_attributes(ssn: "123456789")
      glue_person.addresses.first.update_attributes(address_1: "new york")
      glue_person.emails.first.update_attributes(email_address: "addresstest@gmail.com")
      glue_person
    end

    it "should update if record got changed" do
      glue_home_address = glue_person.addresses.where(address_type: "home").first
      edi_person_hash = edi_gw_person.as_json(include: %i[addresses emails phones name]).deep_symbolize_keys
      result =  People::Persons::Update.new.call(person: edi_person_hash, incoming_person: glue_person)
      expect(result.success?).to be_truthy
      edi_gw_person.reload
      expect(edi_gw_person.name.first_name).to eq glue_person.name_first
      expect(edi_gw_person.name.last_name).to eq glue_person.name_last
      expect(edi_gw_person.addresses.where(kind: "home").first.address_1).to eq(glue_home_address.address_1)
    end
  end

  context "update person record if type is Enroll" do
    let!(:edi_gw_person) { FactoryBot.create(:people_person) }
    let(:enroll_person) { family_entity.family_members.first.person }

    it "should update if record got changed" do
      enroll_home_address = enroll_person.addresses.detect{ |add| add.kind == "home" }
      enroll_home_phone = enroll_person.phones.detect{ |phone| phone.kind == "home" }
      enroll_home_email = enroll_person.emails.detect{ |email| email.kind == "home" }
      edi_person_hash = edi_gw_person.as_json(include: %i[addresses emails phones name]).deep_symbolize_keys
      result =  People::Persons::Update.new.call(person: edi_person_hash, incoming_person: enroll_person, type: "Enroll")
      expect(result.success?).to be_truthy
      edi_gw_person.reload
      expect(edi_gw_person.name.first_name).to eq enroll_person.person_name.first_name
      expect(edi_gw_person.name.last_name).to eq enroll_person.person_name.last_name
      expect(edi_gw_person.addresses.where(kind: "home").first.address_1).to eq(enroll_home_address.address_1)
      expect(edi_gw_person.addresses.where(kind: "home").first.address_2).to eq(enroll_home_address.address_2)
      expect(edi_gw_person.phones.where(kind: "home").first.number).to eq(enroll_home_phone.number)
      expect(edi_gw_person.emails.where(kind: "home").first.address).to eq(enroll_home_email.address)
    end
  end
end
