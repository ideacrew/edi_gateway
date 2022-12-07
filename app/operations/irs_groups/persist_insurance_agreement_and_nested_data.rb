# frozen_string_literal: true

module IrsGroups
  # persist insurance agreements and nested models
  # rubocop:disable Metrics/ClassLength
  class PersistInsuranceAgreementAndNestedData
    include Dry::Monads[:result, :do, :try]
    include EventSource::Command

    def call(params)
      validated_params = yield validate(params)
      @family = validated_params[:family]
      @policies = validated_params[:policies]
      @irs_group = validated_params[:irs_group]
      @primary_person = validated_params[:primary_person]
      insurance_agreements = yield construct_insurance_agreement_and_nested_data
      result = yield persist_insurance_agreement_and_nested_data(insurance_agreements)

      Success(result)
    end

    private

    def validate(params)
      return Failure("Policies should not be blank") if params[:policies].blank?
      return Failure("Family should not be blank") if params[:family].blank?
      return Failure("Irs group should not be blank") if params[:irs_group].blank?
      return Failure("Primary person should not be blank") if params[:primary_person].blank?

      Success(params)
    end

    def construct_insurance_agreement_and_nested_data
      payload = @policies.collect do |policy|
        {
          plan_year: policy.plan.year,
          start_on: policy.subscriber.coverage_start,
          end_on: policy.subscriber.coverage_end,
          contract_holder: construct_member_payload(@primary_person, "self"),
          insurance_provider: construct_insurance_provider_payload(policy),
        }
      end

      Success(payload)
    end

    def persist_insurance_agreement_and_nested_data(insurance_agreements)
      insurance_agreements.each do |agreement|
        @irs_group.insurance_agreements.build(agreement)
        @irs_group.save!
      end
      Success(@irs_group)
    rescue StandardError => e
      Failure("Unable to create Insurance agreements due to #{e}")
    end

    def construct_member_payload(person, relation_code)
      {
        hbx_member_id: person.hbx_id,
        ssn: person.person_demographics.ssn,
        dob: person.person_demographics.dob,
        gender: person.person_demographics.gender,
        relationship_code: relation_code,
        person_name: construct_person_name(person),
        addresses: construct_addresses(person),
        emails: construct_emails(person),
        phones: construct_phones(person)
      }
    end

    def construct_insurance_provider_payload(policy)
      provider = InsurancePolicies::AcaIndividuals::InsuranceProvider.all.where(fein: policy.carrier.fein).first
      {
        title: provider.present? ? provider.title : policy.carrier.name,
        fein: provider.present? ? provider.fein : policy.carrier.fein,
      }
    end

    def construct_person_name(person)
      {
        first_name: person.person_name.first_name,
        last_name: person.person_name.last_name
      }
    end

    def construct_addresses(person)
      person.addresses.collect do |address|
        {
          kind: address.kind,
          address_1: address.address_1,
          address_2: address.address_2,
          address_3: address.address_3,
          city: address.city,
          county: address.county,
          state: address.state,
          zip: address.zip
        }
      end
    end

    def construct_emails(person)
      person.emails.collect do |email|
        {
          kind: email.kind,
          address: email.address
        }
      end
    end

    def construct_phones(person)
      person.phones.collect do |phone|
        {
          kind: phone.kind,
          country_code: phone.country_code,
          area_code: phone.area_code,
          number: phone.number,
          extension: phone.extension,
          primary: phone.primary,
          full_phone_number: phone.full_phone_number
        }
      end
    end
  end
end
# rubocop:enable Metrics/ClassLength
