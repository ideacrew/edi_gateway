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

    def create_operation_file
      template 'operation.rb', File.join('app/operations', class_path, "#{file_name}.rb")
    end

    hook_for :test_framework, in: :rspec, as: :operation
  end
end
