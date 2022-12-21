# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module People
  module Persons
    # Operation to find person by hbx id.
    class Create
      send(:include, Dry::Monads[:result, :do])

      def call(params)
        validated_params = yield validate(params)
        insurance_product = yield create_person(validated_params[:person])

        Success(insurance_product)
      end

      private

      def validate(params)
        return Failure("Person cannot be blank") if params[:person].blank?

        Success(params)
      end

      def create_person(person)
        hbx_id = person.authority_member_id
        person = People::Person.create!(hbx_id: hbx_id,
                                        name: construct_person_name(person),
                                        addresses: construct_addresses(person),
                                        emails: construct_emails(person),
                                        phones: construct_phones(person))

        if person.present?
          person_hash = person.as_json(include: [:addresses, :emails, :phones, :name]).deep_symbolize_keys
          Success(person_hash)
        else
          Failure("Unable to create person")
        end
      end

      def construct_person_name(person)
          {
            first_name: person.name_first,
            last_name: person.name_last
          }
      end

      def construct_addresses(person)
        person.addresses.collect do |address|
          {
            kind: address.address_type,
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
            kind: email.email_type,
            address: email.email_address
          }
        end
      end

      def construct_phones(person)
        person.phones.collect do |phone|
          {
            kind: phone.phone_type,
            country_code: phone.country_code,
            area_code: phone.phone_number.slice(0..2),
            number: phone.phone_number.slice(3..9),
            extension: phone.extension,
            primary: phone.primary
          }
        end
      end
    end
  end
end
