# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'
require 'securerandom'
require 'fileutils'

module Generators
  module Reports
    # This class generates the CMS policy based payments (PBP), SBMI file
    class SbmiSerializer
      send(:include, Dry::Monads[:result, :do])

      def call(params)
        @calendar_year = yield validate(params)
        @sbmi_root_folder = yield create_pbp_folder
        _process = yield initialize_process

        Success("generated pbp successfully")
      end

      private

      def validate(params)
        unless params[:calendar_year].present? || params[:calendar_year].integer?
          Failure('either calendar_year is not present or calendar_year is not an integer')
        end
        @logger = Logger.new("#{Rails.root}/log/pbp_exceptions.log")
        Success(params[:calendar_year])
      end

      # rubocop:disable Metrics/AbcSize
      # rubocop:disable Metrics/MethodLength
      # rubocop:disable Metrics/CyclomaticComplexity
      def initialize_process
        settings = YAML.safe_load(File.read("#{Rails.root}/config/irs_settings.yml")).with_indifferent_access
        hios_prefix_ids = settings[:cms_pbp_generation][:hios_prefix_ids]
        subdirectory_prefix = settings[:cms_pbp_generation][:subdirectory_prefix]

        hios_prefix_ids.each do |hios_prefix|
          plan_ids = Plan.where(hios_plan_id: /^#{hios_prefix}/, year: @calendar_year).pluck(:_id)
          puts "Processing #{hios_prefix}"
          create_sbmi_folder(hios_prefix, subdirectory_prefix)
          count = 0

          policies = Policy.where(:plan_id.in => plan_ids)
          next if policies.blank?

          policies.each do |pol|
            next if pol.rejected?
            next if pol.policy_start < Date.new(@calendar_year, 1, 1)
            next if pol.policy_start > Date.new(@calendar_year, 12, 31)

            if pol.subscriber.person.blank?
              puts "subscriber person record missing #{pol.id}"
              next
            end

            next unless pol.belong_to_authority_member?
            next if pol.kind == 'coverall'

            count += 1
            puts "processing #{count}" if (count % 100).zero?

            begin
              builder = Generators::Reports::SbmiPolicyBuilder.new.call({ policy: pol })
            rescue StandardError => e
              puts "Exception: Policy ID - #{pol.id}"
              puts e.inspect
              @logger.error("Exception: Policy ID - #{pol.id} #{e.backtrace}")
              next
            end

            if builder.success?
              folder_path = "#{@sbmi_root_folder}/#{@sbmi_folder_name}"
              Generators::Reports::SbmiXml.new.call({ sbmi_policy: builder.value!, folder_path: folder_path,
                                                      logger: @logger })
            end
          rescue StandardError => e
            puts "Exception: #{pol.id}"
            puts e.inspect
            @logger.error("Exception: Policy ID - #{pol.id} #{e.backtrace}")
            next
          end

          merge_and_validate_xmls(hios_prefix)
        end
        Success(true)
      end
      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Metrics/MethodLength
      # rubocop:enable Metrics/CyclomaticComplexity

      def merge_and_validate_xmls(hios_prefix)
        xml_merge = Generators::Reports::SbmiXmlMerger.new("#{@sbmi_root_folder}/#{@sbmi_folder_name}")
        xml_merge.sbmi_folder_path = @sbmi_root_folder
        xml_merge.hios_prefix = hios_prefix
        xml_merge.calendar_year = @calendar_year
        xml_merge.process
        xml_merge.validate
      end

      def create_pbp_folder
        pbp_root_folder = "#{Rails.root}/sbmi"
        sbmi = create_directory(pbp_root_folder)
        Success(sbmi)
      end

      def create_sbmi_folder(hios_prefix, subdirectory_prefix)
        @sbmi_folder_name = "#{subdirectory_prefix}_SBMI_#{hios_prefix}_#{Time.now.strftime('%H_%M_%d_%m_%Y')}"
        create_directory "#{@sbmi_root_folder}/#{@sbmi_folder_name}"
      end

      def create_directory(path)
        FileUtils.rm_rf(path)
        FileUtils.mkdir_p(path)[0]
      end
    end
  end
end
