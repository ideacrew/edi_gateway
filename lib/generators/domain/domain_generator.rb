# frozen_string_literal: true

require_relative 'generated_dry_attribute'
require 'rails/generators/actions'

class DomainGenerator < Rails::Generators::NamedBase
  include Rails::Generators::Actions

  source_root File.expand_path('templates', __dir__)
  puts "    \n\n#### LOADED DomainGenerator ####\n\n"

  # Check for required gems
  def gem_check
    gem 'dry-monads'
    gem 'dry-struct'
    gem 'dry-validation'
  end
end
