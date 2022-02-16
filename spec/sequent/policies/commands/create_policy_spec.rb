require "rails_helper"

describe Policies::Commands::CreatePolicy, "given no span" do
  subject do
    described_class.create(
      "1234567",
      "78234",
      nil,
      nil,
      nil,
      nil
    )
  end

  it "is not valid" do
    expect(subject.valid?).to be_falsey
  end
end

describe Policies::Commands::CreatePolicy, "given an invalid span" do
  subject do
    described_class.create(
      "1234567",
      "78234",
      ::Policies::ValueObjects::CoverageSpan.new({
      }),
      nil,
      nil,
      nil
    )
  end

  it "is not valid" do
    expect(subject.valid?).to be_falsey
  end
end

describe Policies::Commands::CreatePolicy, "given a valid span" do
  let(:policy_identifier) { "pi_1234567" }
  let(:product) do
    ::Policies::ValueObjects::Product.new({
      hios_id: "329874902734",
      coverage_year: "2015"
    })
  end

  subject do
    described_class.create(
      policy_identifier,
      "78234",
      ::Policies::ValueObjects::CoverageSpan.new({
        coverage_start: DateTime.now,
        enrollment_id: policy_identifier,
        applied_aptc: "0.00",
        total_cost: "0.00",
        responsible_amount: "0.00"
      }),
      nil,
      product,
      nil
    )
  end

  it "is valid" do
    expect(subject.valid?).to be_truthy
  end

  it "creates the policy and span" do
    Sequent.command_service.execute_commands subject
    policy_record = ::Policies::PolicyRecord.where(policy_identifier: policy_identifier).first
    expect(policy_record).not_to be_nil
    span = policy_record.coverage_span_records.detect { |cs| cs.enrollment_id == policy_identifier }
    expect(span).not_to be_nil
  end
end