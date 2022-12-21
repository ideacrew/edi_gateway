# config/initializers/mongoid.rb
module Mongoid
  module Document
    def as_json(options={})
      attrs = super(options)
      attrs["id"] = attrs.delete('_id') if(attrs.has_key?('_id'))
      attrs
    end
  end
end