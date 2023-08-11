# frozen_string_literal: true

require "dry/core/constants"

require "bigdecimal"
require "bigdecimal/util"
require "date"
require "dry/logic/version"

# Problem Description: https://github.com/dry-rb/dry-logic/issues/104
# The presence of dry-logic version 1.2.0 is leading to a conflict with irb autocomplete functionality, resulting in crashes in the Rails console (rails console).
# Although the conflict has been addressed in dry-logic version 1.5.0, upgrading to this version is not feasible due to dependencies on event source dry gems.
# As a workaround, we are applying a monkey patch to the dry-logic gem in order to resolve the issue.
# This monkey patch is only applied if the dry-logic version is less than 1.5.0.
warn("You may need not this file: if dry-logic gem is upgraded to 1.5.") if Gem::Version.new(Dry::Logic::VERSION) >= Gem::Version.new('1.5')
module Dry
  module Logic
    # This is a monkey patch to fix the issue with irb autocomplete functionality
    module Predicates
      include Dry::Core::Constants

      # This is a monkey patch to fix the issue with irb autocomplete functionality
      module Methods
        # This overrides Object#respond_to? so we need to make it compatible
        def respond_to?(method, input = Undefined)
          return super if input.equal?(Undefined)

          input.respond_to?(method)
        end
      end
    end
  end
end
