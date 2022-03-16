# frozen_string_literal: true

module EdiGateway
  module Error
    # @api private
    module ErrorInitalizer
      attr_reader :original

      # rubocop:disable Style/SpecialGlobalVars
      def initialize(msg, original = $!)
        super(msg)
        @original = original
      end
      # rubocop:enable Style/SpecialGlobalVars
    end

    # @api public
    class Error < StandardError
      include ErrorInitalizer
    end

    ContractError = Class.new(Error)
    EntityError = Class.new(Error)
  end
end
