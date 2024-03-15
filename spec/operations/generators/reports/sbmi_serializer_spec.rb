# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Generators::Reports::SbmiSerializer do
  after(:each) do
    DatabaseCleaner.clean
    FileUtils.rm_rf(Dir["#{Rails.root}/sbmi"])
  end

  let(:plan) { FactoryBot.create(:plan, hios_plan_id: "54879787878782-01") }

  let(:primary) do
    person = FactoryBot.create :person, dob: Date.new(1970, 5, 1), name_first: "John", name_last: "Roberts"
    person.update(authority_member_id: person.members.first.hbx_member_id)
    person
  end

  let!(:child) do
    person = FactoryBot.create :person, dob: Date.new(1998, 9, 6), name_first: "Adam", name_last: "Roberts"
    person.update(authority_member_id: person.members.first.hbx_member_id)
    person
  end

  let(:policy) do
    year = Date.today.year
    policy = FactoryBot.create :policy, plan_id: plan.id, rating_area: "ME0"
    policy.enrollees[0].m_id = primary.authority_member.hbx_member_id
    policy.enrollees[0].coverage_start = Date.new(year, 1, 1)
    policy.enrollees[0].coverage_end = Date.new(year, 12, 31)
    policy.enrollees[1].coverage_start = Date.new(year, 1, 1)
    policy.enrollees[1].coverage_end = Date.new(year, 12, 31)
    policy.enrollees[1].m_id = child.authority_member.hbx_member_id
    policy.enrollees[1].rel_code = 'child'
    policy.save
    policy
  end

  context "SBMI serializer" do
    before do
      allow(policy).to receive(:rejected?).and_return false
    end

    it 'should build sbmi policy struct and return success' do
      result = Generators::Reports::SbmiSerializer.new.call({ calendar_year: Date.today.year })
      expect(result.success?).to be_truthy
      expect(result.value!).to eq "generated pbp successfully"
    end
  end

  context "when cms_eft_serverless feature is turned on" do
    before do
      allow(EdiGatewayRegistry).to receive(:feature_enabled?).with(:cms_eft_serverless).and_return(true)
      allow(policy).to receive(:rejected?).and_return false
      @result = Generators::Reports::SbmiSerializer.new.call({ calendar_year: Date.today.year })
    end

    it 'should generate PBP successfully' do
      expect(@result.success?).to be_truthy
    end

    it 'should transmission batch file' do
      file_names = Dir.glob("#{Rails.root}/sbmi/*").collect do |file|
        File.basename(file)
      end
      expect(file_names.last).to match(/SBE00ME\.EPS\.SBMI\.D\d{6}\.T\d{9}\.P/)
    end
  end

  context "when cms_eft_serverless feature is turned off" do
    before do
      allow(EdiGatewayRegistry).to receive(:feature_enabled?).with(:cms_eft_serverless).and_return(false)
      allow(policy).to receive(:rejected?).and_return false
      @result = Generators::Reports::SbmiSerializer.new.call({ calendar_year: Date.today.year })
    end

    it 'should generate PBP successfully' do
      expect(@result.success?).to be_truthy
    end

    it 'should transmission batch file' do
      file_names = Dir.glob("#{Rails.root}/sbmi/*").collect do |file|
        File.basename(file)
      end
      expect(file_names.last).to match(/SBE00ME\.EPS\.SBMI\.D\d{6}\.T\d{9}\.P\.IN/)
    end
  end
end
