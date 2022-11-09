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
      @policies = validated_params[:policies]
      @irs_group = yield create_or_update_irs_group
      result = yield create_insurance_agreement_and_nested_data

      Success(result)
    end

    private

    def validate(params)
      return Failure("Please pass in family entity") if params[:family].blank?
      return Failure("Policies are blank") if params[:policies].blank?

      Success(params)
    end

    def create_or_update_irs_group
      existing_irs_group = fetch_irs_group
      irs_group = if existing_irs_group.present?
                    existing_irs_group.insurance_agreements = []
                    existing_irs_group.save!
                    existing_irs_group
                  else
                    create_new_irs_group
                  end

      Success(irs_group)
    end

    def create_new_irs_group
      year = Date.today.year
      hbx_id = @primary_person.hbx_id
      irs_group_id = construct_irs_group_id(year.to_s.last(2), hbx_id)
      policy_start_date = @policies.map(&:subscriber).min_by(&:coverage_start)&.coverage_start
      start_on = policy_start_date || Date.today.beginning_of_year
      irs_group = InsurancePolicies::AcaIndividuals::IrsGroup.new(irs_group_id: irs_group_id, start_on: start_on,
                                                                  family_assigned_hbx_id: @family_entity.hbx_id)
      irs_group.save!
      irs_group
    end

    def fetch_irs_group
      InsurancePolicies::AcaIndividuals::IrsGroup.where(family_assigned_hbx_id: @family_entity.hbx_id).first
    end

    def create_insurance_agreement_and_nested_data
      group_by_carriers = @policies.group_by(&:carrier_id)
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
      hbx_id_number = format("%0#{total_length_excluding_year}d", hbx_id)
      year + hbx_id_number
    end

    def prepend_zeros(number, length)
      length.times { number.prepend('0') }
      number
    end
  end
end
