# frozen_string_literal: true

module Domain
  # Generator that adds Domain Model to a Rails application
  class InstallGenerator < Rails::Generators::Base
    source_root File.expand_path('../../templates', __FILE__)

    def initialize(*args, &blk)
      super(*args, &blk)
      @app_name = app_name
    end

    desc 'Create Domain folder, Contract subfolder, Application folder and copy a custom Types file'

    def create_contract_file
      template 'contract.rb', File.join('app/domain/contracts', 'contract.rb') if behavior == :invoke
    end

    def create_types_file
      template 'types.rb', File.join("app/domain/#{@app_name}", 'types.rb') if behavior == :invoke
    end

    hook_for :test_framework, in: :rspec, as: :install

    private

    def app_name
      Rails.application.class.name.chomp('::Application').underscore
    end
  end
end
