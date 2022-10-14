# frozen_string_literal: true

module IrsGroups
  # The location of an H36 XML file.
  class H36LocationContract < Dry::Validation::Contract
    params do
      required(:path).value(:string)
    end
  end
end
