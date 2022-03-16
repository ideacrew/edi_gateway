# frozen_string_literal: true

require 'dry-types'
require 'bigdecimal'
require 'securerandom'

module EdiGateway
  # Extend DryTypes
  module Types
    send(:include, Dry.Types)
    send(:include, Dry::Logic)

    CorrelationIdKind = Types.Constructor(SecureRandom, &:uuid)
    UriKind = Types.Constructor(URI) { |value| URI(value) }
  end
end
