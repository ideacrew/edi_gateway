require "rails_helper"

describe Policies::Commands::CreatePolicy, "given no span" do
  subject do
    described_class.create(
      "1234567",
      "78234",
      nil,
      nil,
      nil,
      "ME-0",
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
      "ME-0",
      nil
    )
  end

  it "is not valid" do
    expect(subject.valid?).to be_falsey
  end
end

describe Policies::Commands::CreatePolicy, "given a valid span with no end" do
  let(:policy_identifier) { "pi_1234567" }
  let(:product) do
    ::Policies::ValueObjects::Product.new({
      hios_id: "329874902734",
      coverage_year: "2015"
    })
  end

  let(:coverage_start) do
    DateTime.new(
      2022,
      1,
      1,
      0,
      0,
      0,
      0
    )
  end


  let(:coverage_end) do
    DateTime.new(
      2022,
      1,
      31,
      0,
      0,
      0,
      0
    )
  end

  subject do
    described_class.create(
      policy_identifier,
      "78234",
      ::Policies::ValueObjects::CoverageSpan.new({
        coverage_start: coverage_start,
        enrollment_id: policy_identifier,
        applied_aptc: "0.00",
        total_cost: "0.00",
        responsible_amount: "0.00"
      }),
      nil,
      product,
      "ME-0",
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

  it "is searchable for invoices" do
    Sequent.command_service.execute_commands subject
    policy_record = ::Policies::PolicyRecord.in_billing_interval_range_with_product(
      "329874902734",
      2015,
      coverage_start,
      coverage_end
    ).first
    expect(policy_record).not_to be_nil
  end
end

describe Policies::Commands::CreatePolicy, "given a valid span with an end" do
  let(:policy_identifier) { "pi_1234567" }
  let(:product) do
    ::Policies::ValueObjects::Product.new({
      hios_id: "329874902734",
      coverage_year: "2015"
    })
  end

  let(:coverage_start) do
    DateTime.new(
      2022,
      1,
      1,
      0,
      0,
      0,
      0
    )
  end


  let(:coverage_end) do
    DateTime.new(
      2022,
      1,
      15,
      0,
      0,
      0,
      0
    )
  end

  let(:month_end) do
    DateTime.new(
      2022,
      1,
      31,
      0,
      0,
      0,
      0
    )
  end  

  subject do
    described_class.create(
      policy_identifier,
      "78234",
      ::Policies::ValueObjects::CoverageSpan.new({
        coverage_start: coverage_start,
        coverage_end: coverage_end,
        enrollment_id: policy_identifier,
        applied_aptc: "0.00",
        total_cost: "0.00",
        responsible_amount: "0.00"
      }),
      nil,
      product,
      "ME-0",
      nil
    )
  end

  it "is valid" do
    expect(subject.valid?).to be_truthy
  end

  it "is searchable for invoices" do
    Sequent.command_service.execute_commands subject
    policy_record = ::Policies::PolicyRecord.in_billing_interval_range_with_product(
      "329874902734",
      2015,
      coverage_start,
      month_end
    ).first
    expect(policy_record).not_to be_nil
  end
end