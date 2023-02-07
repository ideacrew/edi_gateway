# frozen_string_literal: true

module BSON
  # monkeypatch mongoid objectId method
  class ObjectId
    alias as_json to_s
  end
end
