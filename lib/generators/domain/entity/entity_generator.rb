# frozen_string_literal: true

require_relative '../generated_dry_attribute'

module Domain
  # Generate a Domain Entity file
  class EntityGenerator < Rails::Generators::NamedBase
    source_root File.expand_path('templates', __dir__)

    ENTITY_PATH = 'app/domain'
    ENTITY_TEMPLATE_FILENAME = 'entity.rb'
    OPTIONAL_META = 'meta(ommitable: true)'
    REQUIRED_META = 'meta(ommitable: false)'

    desc 'Generate a Domain Entity file with optional attributes'

    argument :attributes,
             type: :array,
             default: [],
             banner:
               'ATTRIBUTE_NAME[:type][:optional_key (default) | :require_key] ATTRIBUTE_NAME[:type][:optional_key (default) | :require_key]'

    check_class_collision

    def initialize(*args, &blk)
      @local_args = args[0]
      super(*args, &blk)

      @local_class_name = class_name.to_s.split('::').last
      @indentation = 2
    end

    # Convert attributes array into GeneratedDryAttribute objects
    def parse_dry_attributes
      attrs = @local_args.drop(1)
      self.attributes = (attrs || []).map { |attr| Generators::Domain::GeneratedDryAttribute.parse(attr) }
    end

    def copy_entity_file
      template ENTITY_TEMPLATE_FILENAME, entity_filename
    end

    def generate_contract
      case self.behavior
      when :invoke
        generate 'domain:contract', @local_args
      when :revoke
        Rails::Generators.invoke 'domain:contract', @local_args, behavior: :revoke
      end
    end

    hook_for :test_framework, in: :rspec, as: :entity

    private

    def content
      attributes.reduce('') do |block, attr|
        param = attr.key_required? ? required_attribute(attr) : optional_attribute(attr)
        block + param
      end
    end

    def entity_filename
      File.join(ENTITY_PATH, class_path, "#{file_name}.rb")
    end

    def required_attribute(attr)
      data_type = attr.type.to_s.camelcase
      attr_name = attr.name.underscore
      <<~ATTR.chomp

        # @!attribute [r] #{attr_name}
        # ** REPLACE WITH DEFINITION FOR ATTRIBUTE: :#{attr_name} **
        # @return [#{data_type}]
        attribute :#{attr_name}, Types::#{data_type}.#{REQUIRED_META}

      ATTR
    end

    def optional_attribute(attr)
      data_type = attr.type.to_s.camelcase
      attr_name = attr.name.underscore
      <<~ATTR.chomp

        # @!attribute [r] #{attr_name}
        # ** REPLACE WITH DEFINITION FOR ATTRIBUTE: :#{attr_name} **
        # @return [#{data_type}]
        attribute? :#{attr_name}, Types::#{data_type}.#{OPTIONAL_META}\n
      ATTR
    end
  end
end
