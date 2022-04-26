# frozen_string_literal: true

module Domain # :nodoc:
  class OperationGenerator < Rails::Generators::NamedBase # :nodoc:
    source_root File.expand_path('templates', __dir__)

    desc 'Create Domain Operation file'

    argument :params,
             type: :array,
             default: [],
             banner:
               'ATTRIBUTE_NAME[:type][:optional_key (default) | :require_key] ATTRIBUTE_NAME[:type][:optional_key (default) | :require_key]'

    check_class_collision

    # class_option :params
    # class_option :indexes, type: :boolean, default: true, desc: "Add indexes for references and belongs_to columns"
    # class_option :primary_key_type, type: :string, desc: "The type for primary key"
    # class_option :database, type: :string, aliases: %i(--db), desc: "The database for your model's migration. By default, the current environment's primary database is used."

    def create_operation_file
      template 'operation.rb', File.join('app/operations', class_path, "#{file_name}.rb")
    end

    hook_for :test_framework, in: :rspec, as: :operation
  end
end
