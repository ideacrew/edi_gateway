require "rails_helper"

describe PolicyInventory::ImportSpanRecord, "given a new span" do
  let(:enrollees) {
    [
      {
        hbx_member_id: "89782",
        relationship: "self",
        premium: "0.00",
        tobacco_usage: "U"
      }
    ]
  }

  let(:product) do
    {
      hios_id: "329874902734",
      coverage_year: "2015"
    }
  end

  let(:coverage_span) do
    {
      enrollment_id: "23897982314",
      coverage_start: DateTime.now,
      enrollees: enrollees,
      applied_aptc: "0.00",
      responsible_amount: "0.00",
      total_cost: "0.00"
    }
  end

  let(:params) do
    {
      subscriber_hbx_id: "897982",
      policy_identifier: "23897982314",
      coverage_span: coverage_span,
      product: product,rating_area: "ME-0"
    }
  end

  it "imports the span" do
    result = described_class.new.call(params)
    expect(result.success?).to be_truthy
  end
end

describe PolicyInventory::ImportSpanRecord, "given a span that already exists" do
  let(:enrollees) {
    [
      {
        hbx_member_id: "89782",
        relationship: "self",
        premium: "0.00",
        tobacco_usage: "U"
      }
    ]
  }

  let(:product) do
    {
      hios_id: "329874902734",
      coverage_year: "2015"
    }
  end

  let(:coverage_span) do
    {
      enrollment_id: "23897314",
      coverage_start: DateTime.now,
      applied_aptc: "0.00",
      responsible_amount: "0.00",
      total_cost: "0.00",
      enrollees: enrollees
    }
  end

  let(:params) do
    {
      subscriber_hbx_id: "89782",
      policy_identifier: "23897314",
      coverage_span: coverage_span,
      product: product,
      rating_area: "ME-0"
    }
  end

  it "fails" do
    described_class.new.call(params)
    expect(described_class.new.call(params).success?).to be_falsey
  end
end

describe PolicyInventory::ImportSpanRecord, "given a span that matches datewise, but doesn't have the same tobacco rating" do
  let(:subscriber_id) { "8978246546" }

  let(:enrollees1) {
    [
      {
        hbx_member_id: subscriber_id,
        relationship: "self",
        premium: "0.00",
        tobacco_usage: "U"
      }
    ]
  }

  let(:enrollees2) {
    [
      {
        hbx_member_id: subscriber_id,
        relationship: "self",
        premium: "0.00",
        tobacco_usage: "N"
      }
    ]
  }

  let(:enrollment_id1) { "2389798254354314" }
  let(:enrollment_id2) { "23897982234314" }

  let(:product) do
    {
      hios_id: "329874902734",
      coverage_year: "2015"
    }
  end

  let(:coverage_span1) do
    {
      enrollment_id: enrollment_id1,
      coverage_start: DateTime.now,
      enrollees: enrollees1,
      applied_aptc: "0.00",
      responsible_amount: "0.00",
      total_cost: "0.00"
    }
  end

  let(:coverage_span2) do
    {
      enrollment_id: enrollment_id2,
      coverage_start: DateTime.now,
      enrollees: enrollees2,
      applied_aptc: "0.00",
      responsible_amount: "0.00",
      total_cost: "0.00"
    }
  end

  let(:params1) do
    {
      subscriber_hbx_id: subscriber_id,
      policy_identifier: enrollment_id1,
      coverage_span: coverage_span1,
      product: product,
      rating_area: "ME-0"
    }
  end

  let(:params2) do
    {
      subscriber_hbx_id: subscriber_id,
      policy_identifier: enrollment_id2,
      coverage_span: coverage_span2,
      product: product,
      rating_area: "ME-0"
    }
  end

  it "imports the span" do
    described_class.new.call(params1)
    result = described_class.new.call(params2)
    expect(result.success?).to be_truthy
  end
end

describe PolicyInventory::ImportSpanRecord, "given a span that matches datewise, and has the same tobacco rating" do
  let(:subscriber_id) { "897826767546" }

  let(:enrollees1) {
    [
      {
        hbx_member_id: subscriber_id,
        relationship: "self",
        premium: "0.00",
        tobacco_usage: "U"
      }
    ]
  }

  let(:enrollees2) {
    [
      {
        hbx_member_id: subscriber_id,
        relationship: "self",
        premium: "0.00",
        tobacco_usage: "U"
      }
    ]
  }

  let!(:start_date1) { DateTime.now }
  let(:end_date1) { start_date1 + 1.week }
  let!(:start_date2) { end_date1 + 1.day }

  let(:enrollment_id1) { "23897982233214298934" }
  let(:enrollment_id2) { "238979822332234214" }

  let(:product) do
    {
      hios_id: "329874902734",
      coverage_year: "2015"
    }
  end

  let(:coverage_span1) do
    {
      enrollment_id: enrollment_id1,
      coverage_start: start_date1,
      coverage_end: end_date1,
      enrollees: enrollees1,
      applied_aptc: "0.00",
      responsible_amount: "0.00",
      total_cost: "0.00"
    }
  end

  let(:coverage_span2) do
    {
      enrollment_id: enrollment_id2,
      coverage_start: start_date2,
      enrollees: enrollees2,
      applied_aptc: "0.00",
      responsible_amount: "0.00",
      total_cost: "0.00"
    }
  end

  let(:params1) do
    {
      subscriber_hbx_id: subscriber_id,
      policy_identifier: enrollment_id1,
      coverage_span: coverage_span1,
      product: product,
      rating_area: "ME-0"
    }
  end

  let(:params2) do
    {
      subscriber_hbx_id: subscriber_id,
      policy_identifier: enrollment_id2,
      coverage_span: coverage_span2,
      product: product,
      rating_area: "ME-0"
    }
  end

  it "adds the span to the existing policy" do
    described_class.new.call(params1)
    result = described_class.new.call(params2)
    expect(result.success?).to be_truthy
  end
end