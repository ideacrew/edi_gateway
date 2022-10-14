# frozen_string_literal: true

module IrsGroups
  # Parameters to request recon of a set of H36 files with policies.
  class H36ReconRequestContract < Dry::Validation::Contract
    params do
      required(:path).value(:string)
      required(:year).value(:integer)
    end
  end
end
