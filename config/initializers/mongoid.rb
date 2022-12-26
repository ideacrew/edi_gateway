# frozen_string_literal: true

# config/initializers/mongoid.rb
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
