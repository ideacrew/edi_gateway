# frozen_string_literal: true

require "dry/logic/predicates"

RSpec.describe Dry::Logic::Predicates do
  describe '.respond_to?' do
    it 'works with a just the method name' do
      expect(Dry::Logic::Predicates.respond_to?(:predicate)).to be(true)
      expect(Dry::Logic::Predicates.respond_to?(:not_here)).to be(false)
    end
  end
end