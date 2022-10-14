# frozen_string_literal: true

module EdiDatabase
  # Parameters to query policy information restricted to a calendar year.
  class PolicyYearQueryContract < Dry::Validation::Contract
    params do
      required(:year).value(:integer)
    end
  end
end
