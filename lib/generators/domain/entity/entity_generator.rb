# frozen_string_literal: true

require_relative '../generated_dry_attribute'

module Domain
  # Generate a Domain Entity file
  class EntityGenerator < Rails::Generators::NamedBase
    source_root File.expand_path('templates', __dir__)

    # namespace 'domain'

    OptionalMeta = 'meta(ommitable: true)'
    RequiredMeta = 'meta(ommitable: false)'

    desc 'Generate a Domain Entity file with optional attributes'

    # readme 'README'

    argument :attributes,
             type: :array,
             default: [],
             banner:
               'ATTRIBUTE_NAME[:type][:optional_key (default) | :require_key] ATTRIBUTE_NAME[:type][:optional_key (default) | :require_key]'

    check_class_collision

    def initialize(*args, &blk)
      @local_args = args[0].dup
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
      template 'entity.rb', entity_filename
    end

    hook_for :test_framework, in: :rspec, as: :entity

    def generate_contract
      generate 'domain:contract', @local_args
    end

    private

    def content
      attributes.reduce('') do |block, attr|
        param = attr.key_required? ? required_attribute(attr) : optional_attribute(attr)
        block + param
      end
    end

    def entity_filename
      File.join('app/domain', class_path, "#{file_name}.rb")
    end

    def required_attribute(attr)
      data_type = attr.type.to_s.camelcase
      attr_name = attr.name.underscore
      <<~ATTR.chomp

        # @!attribute [r] #{attr_name}
        # ** REPLACE WITH DEFINITION FOR ATTRIBUTE: :#{attr_name} **
        # @return [#{data_type}]
        attribute :#{attr_name}, Types::#{data_type}.#{RequiredMeta}

      ATTR
    end

    def optional_attribute(attr)
      data_type = attr.type.to_s.camelcase
      attr_name = attr.name.underscore
      <<~ATTR.chomp

        # @!attribute [r] #{attr_name}
        # ** REPLACE WITH DEFINITION FOR ATTRIBUTE: :#{attr_name} **
        # @return [#{data_type}]
        attribute? :#{attr_name}, Types::#{data_type}.#{OptionalMeta}\n
      ATTR
    end
  end
end
