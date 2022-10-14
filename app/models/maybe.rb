# frozen_string_literal: true

# This class used for xml generation
class Maybe
  attr_reader :value

  def initialize(obj)
    @value = obj
  end

  def fmap(&the_proc)
    @value.nil? ? Maybe.new(nil) : Maybe.new(the_proc.call(@value))
  end

  # rubocop:disable Style/MissingRespondToMissing

  def method_missing(msg, *args, &block)
    target = @value
    self.class.new(target.nil? ? nil : target.__send__(msg, *args, &block))
  end

  # rubocop:enable Style/MissingRespondToMissing
end
