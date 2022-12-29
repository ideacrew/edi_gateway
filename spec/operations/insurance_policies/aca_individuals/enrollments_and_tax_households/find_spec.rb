# frozen_string_literal: true

require 'shared_examples/cv3_family'

RSpec.describe InsurancePolicies::AcaIndividuals::EnrollmentsAndTaxHouseholds::Find do
  subject { described_class.new }
  include_context 'cv3_family'

  let!(:enr_thh) { FactoryBot.create(:enrollments_tax_households) }
  let!(:enr) { enr_thh.enrollment }
  let!(:thh) { enr_thh.tax_household }

  context 'with invalid payload' do
    it "return failure" do
      res = subject.call({ scope_name: :by_enrollment_id_tax_household_id,
                           enrollment_id: enr.id,
                           tax_household_id: "" })
      expect(res.failure?).to be_truthy
    end
  end

  context 'with valid payload' do
    it "return success" do
      res = subject.call({ scope_name: :by_enrollment_id_tax_household_id,
                           enrollment_id: enr.id,
                           tax_household_id: thh.id })
      expect(res.success?).to be_truthy
    end

    it "return object hash" do
      res = subject.call({ scope_name: :by_enrollment_id_tax_household_id,
                           enrollment_id: enr.id,
                           tax_household_id: thh.id })
      expect(res.success.class).to be Hash
    end
  end
end
