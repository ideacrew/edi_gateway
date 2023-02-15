# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module People
  module Persons
    # Operation to find person by hbx id.
    class Update
      send(:include, Dry::Monads[:result, :do])

      def call(params)
        values = yield validate(params)
        person = yield find_person_record(values)
        insurance_product = yield update_person(person, values)

        Success(insurance_product)
      end

      private

      def validate(params)
        return Failure('Person cannot be blank') if params[:person].blank?
        return Failure('Person cannot be blank') if params[:incoming_person].blank?

        @type = params[:type] || 'Glue'

        Success(params)
      end

      def find_person_record(values)
        person = People::Person.where(hbx_id: values[:person][:hbx_id]).first
        return Failure("unable to find person with #{values[:person][:hbx_id]}") unless person

        Success(person)
      end

      def compare_and_update_addresses(person, incoming_person)
        comparable = Integrations::CompareRecords.new(AcaEntities::Locations::Address, :kind)
        comparable.add_old_entry(fetch_person_addresses(person))
        comparable.add_new_entry(construct_addresses(incoming_person))
        comparable.changed_records

        comparable.records_to_delete { |record| person.addresses.delete_if { |address| address.kind == record[:kind] } }
        comparable.records_to_create { |record| person.addresses.create(record) }
        comparable.records_to_update do |record|
          address_record = person.addresses.detect { |address| address.kind == record[:kind] }
          address_record.update(record)
        end
      end

      def compare_and_update_emails(person, incoming_person)
        comparable = Integrations::CompareRecords.new(AcaEntities::Contacts::EmailContact, :kind)
        comparable.add_old_entry(fetch_person_emails(person))
        comparable.add_new_entry(construct_emails(incoming_person))
        comparable.changed_records

        comparable.records_to_delete { |record| person.emails.delete_if { |address| address.kind == record[:kind] } }
        comparable.records_to_create { |record| person.emails.create(record) }
        comparable.records_to_update do |record|
          email_record = person.emails.detect { |email| email.kind == record[:kind] }
          email_record.update(record)
        end
      end

      def compare_and_update_phones(person, incoming_person)
        comparable = Integrations::CompareRecords.new(AcaEntities::Contacts::PhoneContact, :kind)
        comparable.add_old_entry(fetch_person_phones(person))
        comparable.add_new_entry(construct_phones(incoming_person))
        comparable.changed_records

        comparable.records_to_delete { |record| person.phones.delete_if { |address| address.kind == record[:kind] } }
        comparable.records_to_create { |record| person.phones.create(record) }
        comparable.records_to_update do |record|
          phone_record = person.phones.detect { |phone| phone.kind == record[:kind] }
          phone_record.update(record)
        end
      end

      def update_person(person, values)
        incoming_person = values[:incoming_person]

        compare_and_update_addresses(person, incoming_person)
        compare_and_update_emails(person, incoming_person)
        compare_and_update_phones(person, incoming_person)

        person_hash = person.as_json(include: %i[addresses emails phones name]).deep_symbolize_keys
        Success(person_hash)
      end

      def construct_person_name(person)
        {
          first_name: @type == 'Enroll' ? person.person_name.first_name : person.name_first,
          last_name: @type == 'Enroll' ? person.person_name.last_name : person.name_last,
          name_pfx: @type == 'Enroll' ? person.person_name.name_pfx : person.name_pfx,
          name_sfx: @type == 'Enroll' ? person.person_name.name_sfx : person.name_sfx,
          middle_name: @type == 'Enroll' ? person.person_name.middle_name : person.name_middle
        }
      end

      def fetch_person_addresses(person)
        person.addresses.collect do |address|
          address.attributes.slice(
            :kind,
            :address_1,
            :address_2,
            :address_3,
            :city_name,
            :county_name,
            :state_abbreviation,
            :zip_code
          )
        end
      end

      def fetch_person_emails(person)
        person.emails.collect { |email| email.attributes.slice(:kind, :address) }
      end

      def fetch_person_phones(person)
        person.phones.collect do |phone|
          phone.attributes.slice(:kind, :country_code, :area_code, :number, :extension, :primary)
        end
      end

      def construct_addresses(person)
        person.addresses.collect do |address|
          {
            kind: @type == 'Enroll' ? address.kind : address.address_type,
            address_1: address.address_1,
            address_2: address.address_2,
            address_3: address.address_3,
            city_name: address.city,
            county_name: address.county,
            state_abbreviation: address.state,
            zip_code: address.zip
          }
        end
      end

      def construct_emails(person)
        person.emails.collect do |email|
          {
            kind: @type == 'Enroll' ? email.kind : email.email_type,
            address: @type == 'Enroll' ? email.address : email.email_address
          }
        end
      end

      def construct_phones(person)
        person.phones.collect do |phone|
          {
            kind: @type == 'Enroll' ? phone.kind : phone.phone_type,
            country_code: phone.country_code,
            area_code: @type == 'Enroll' ? phone.area_code : phone.phone_number.slice(0..2),
            number: @type == 'Enroll' ? phone.number : phone.phone_number.slice(3..9),
            extension: phone.extension,
            primary: phone.primary
          }
        end
      end
    end
  end
end
