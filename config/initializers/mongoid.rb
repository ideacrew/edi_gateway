# frozen_string_literal: true

# config/initializers/mongoid.rb

# Latest rails version belongs_to associations is required by default, so that saving a
# # model with a missing belongs_to association will trigger a validation
# Mark this default to false, belongs_to is not longer required.
Mongoid::Config.belongs_to_required_by_default = false
module Mongoid
  # monkeypatch mongoid as_json method
  module Document
    def as_json(options = {})
      attrs = super(options)
      attrs["id"] = attrs.delete('_id') if attrs.key?('_id')
      attrs
    end
  end
end
