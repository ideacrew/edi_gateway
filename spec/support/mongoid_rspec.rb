require 'mongoid-rspec'

RSpec.configure { |config| config.include Mongoid::Matchers, type: :model }
