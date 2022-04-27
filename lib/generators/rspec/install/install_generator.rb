# frozen_string_literal: true

module Rspec
  # Generate a Domain Types rspec file
  class InstallGenerator < Rails::Generators::NamedBase
    source_root File.expand_path('templates', __dir__)

    desc 'Create Domain Types rspec file'

    class_option :install_specs, type: :boolean, default: true

    def copy_types_spec_file
      return unless options[:install_specs]
      @app_name = Rails.application.class.name.chomp('::Application').underscore
      template 'types_spec.rb', File.join("spec/domain/#{@app_name}", class_path, 'types_spec.rb')
    end
  end
end
