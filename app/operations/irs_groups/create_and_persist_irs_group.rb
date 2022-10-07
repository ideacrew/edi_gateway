# frozen_string_literal: true

module IrsGroups
  # Create and Persist IRS group and its data
  class CreateAndPersistIrsGroup
    include Dry::Monads[:result, :do, :try]
    include EventSource::Command
    require 'dry/monads'
    require 'dry/monads/do'

    def call(params)
      validated_params = yield validate(params)
      @family_entity = validated_params[:family]
      @primary_person = yield fetch_primary_person(@family_entity)
      @irs_group = yield create_irs_group
      result = yield create_insurance_agreement_and_nested_data(validated_params[:policies])

      Success(result)
    end

    private

    def validate(params)
      return Failure("Please pas in family entity") if params[:family].blank?
      return Failure("Policies are blank") if params[:policies].blank?

      Success(params)
    end

    def create_irs_group
      year = Date.today.year
      irs_group_id = construct_irs_group_id(year.to_s.last(2), @primary_person.hbx_id)
      irs_group = InsurancePolicies::AcaIndividuals::IrsGroup.new(irs_group_id: irs_group_id, start_on: Date.today)
      irs_group.save!
      Success(irs_group)
    end

    def create_insurance_agreement_and_nested_data(policies)
      group_by_carriers = policies.group_by(&:carrier_id)
      group_by_carriers.each do |_id, enrollments|
        PersistInsuranceAgreementAndNestedData.new.call({ policies: enrollments, family: @family_entity,
                                                          irs_group: @irs_group, primary_person: @primary_person })
      end

      Success(@irs_group)
    end

    def fetch_primary_person(family)
      primary_family_member =
        family.family_members.detect(&:is_primary_applicant)
      if primary_family_member
        Success(primary_family_member.person)
      else
        Failure('No Primary Applicant in family members')
      end
    end

    # year + subscriber_id (pad with zero to the left)
    # Total length should be 16 digit
    def construct_irs_group_id(year, hbx_id)
      total_length_excluding_year = 14
      hbx_id_length = hbx_id.length
      hbx_id_number = prepend_zeros(hbx_id, (total_length_excluding_year - hbx_id_length))

      year + hbx_id_number
    end

    def prepend_zeros(number, length)
      length.times { number.prepend('0') }
      number
    end
  end
end
