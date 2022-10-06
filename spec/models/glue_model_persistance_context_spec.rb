# frozen_string_literal: true

require "rails_helper"

# The specs in this file verify that we are reading our 'gluedb' records from
# the correct secondary database, and that no top-level classes have been
# been introduced which collide with our GlueDB legacy model names.

STORAGE_CLIENT_NAME = :edidb

describe AptcCredit do
  it "is read from the correct database context" do
    expect(described_class.persistence_context.client_name).to eq STORAGE_CLIENT_NAME
  end
end

describe Broker do
  it "is read from the correct database context" do
    expect(described_class.persistence_context.client_name).to eq STORAGE_CLIENT_NAME
  end
end

describe Carrier do
  it "is read from the correct database context" do
    expect(described_class.persistence_context.client_name).to eq STORAGE_CLIENT_NAME
  end
end

describe Enrollee do
  it "is read from the correct database context" do
    expect(described_class.persistence_context.client_name).to eq STORAGE_CLIENT_NAME
  end
end

describe Member do
  it "is read from the correct database context" do
    expect(described_class.persistence_context.client_name).to eq STORAGE_CLIENT_NAME
  end
end

describe Person do
  it "is read from the correct database context" do
    expect(described_class.persistence_context.client_name).to eq STORAGE_CLIENT_NAME
  end
end

describe Plan do
  it "is read from the correct database context" do
    expect(described_class.persistence_context.client_name).to eq STORAGE_CLIENT_NAME
  end
end

describe Policy do
  it "is read from the correct database context" do
    expect(described_class.persistence_context.client_name).to eq STORAGE_CLIENT_NAME
  end
end

describe ResponsibleParty do
  it "is read from the correct database context" do
    expect(described_class.persistence_context.client_name).to eq STORAGE_CLIENT_NAME
  end
end
