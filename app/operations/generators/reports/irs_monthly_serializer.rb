# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
require 'dry/monads'
require 'dry/monads/do'
require 'securerandom'
require 'fileutils'

module Generators
  module Reports
    # This class generates a monthly IRS report
    class IrsMonthlySerializer
      send(:include, Dry::Monads[:result, :do])

      def call(params)
        calendar_year, max_month = yield validate(params)
        @h36_root_folder = yield create_h36_folder
        transmission_folder = yield create_transmission_folder
        irs_group_query = yield fetch_irs_groups
        _execute = yield initialize_process(calendar_year, max_month, irs_group_query)
        _manifest = yield create_manifest(transmission_folder)
        Success("generated h36 successfully")
      end

      private

      def validate(params)
        unless params[:calendar_year].present? || params[:calendar_year].integer?
          Failure('either calendar_year is not present or calendar_year is not an integer')
        end
        unless params[:max_month].present? || params[:max_month].integer?
          Failure('either max_month is not present or max_month is not an integer')
        end
        @logger = Logger.new("#{Rails.root}/log/h36_exceptions.log")
        Success([params[:calendar_year], params[:max_month]])
      end

      def create_h36_folder
        path = "#{Rails.root}/irs/h36_#{Time.now.strftime('%m_%d_%Y_%H_%M')}"
        h36_root_folder = create_directory(path)
        Success(h36_root_folder)
      end

      def create_transmission_folder
        transmission_folder = create_directory("#{@h36_root_folder}/transmission")

        Success(transmission_folder)
      end

      def create_directory(path)
        FileUtils.rm_rf(path)
        FileUtils.mkdir_p(path)[0]
      end

      def fetch_irs_groups
        Success InsurancePolicies::AcaIndividuals::IrsGroup.all
      end

      # rubocop:disable Metrics/AbcSize
      # rubocop:disable Metrics/CyclomaticComplexity
      # rubocop:disable Metrics/PerceivedComplexity
      # rubocop:disable Metrics/MethodLength

      def initialize_process(calendar_year, max_month, fetch_irs_groups)
        total_count = fetch_irs_groups.count
        folder_count = 1
        create_new_irs_folder(folder_count)
        count = 0
        start = Time.now

        fetch_irs_groups.no_timeout.each do |irs_group|
          contract_holder = irs_group.aca_individual_insurance_policies.last.insurance_agreement&.contract_holder
          if contract_holder.nil?
            @logger.info("contract_holder not found for irs_group: #{irs_group.irs_group_id}")
            next
          end

          if irs_group.tax_household_groups.empty?
            @logger.info("No tax households found for irs_group: #{irs_group.irs_group_id}, person: #{contract_holder.hbx_id}")
            next
          end

          policies = irs_group.aca_individual_insurance_policies
          result = policies.reject do |pol|
            non_eligible_policy(pol, calendar_year, max_month)
          end

          if result.count.zero?
            @logger.info("No policies found for irs_group_id: #{irs_group.irs_group_id}")
            next
          end

          sorted_policies = result.sort_by(&:start_on)
          folder_path = "#{@h36_root_folder}/#{@h36_folder_name}"
          group_xml = Generators::Reports::IrsMonthlyXml.new(irs_group, sorted_policies, calendar_year, max_month, folder_path)
          group_xml.serialize

          count += 1

          puts "----found #{count} IRS Groups so far" if (count % 50).zero?

          if (count % 3000).zero?
            merge_and_validate_xmls(folder_count)
            folder_count += 1
            create_new_irs_folder(folder_count)
          end

          if (count % 100).zero?
            puts "so far --- #{count} --- out of #{total_count}"
            puts "time taken for current record ---- #{Time.now - start} seconds"
            start = Time.now
          end
        rescue StandardError => e
          @logger.info("Unable to create IRS Group for: #{irs_group.irs_group_id} due to #{e}")
        end
        merge_and_validate_xmls(folder_count)
        Success("executed successfully")
      end

      def non_eligible_policy(pol, calendar_year, max_month)
        return true if pol.aasm_state == "canceled"
        return true if pol.insurance_product.coverage_type == 'dental'
        return true if pol.insurance_product.metal_level == "catastrophic"
        return true if pol.carrier_policy_id.blank?
        return true if pol.start_on.year != calendar_year
        return true if max_month != 12 && (pol.start_on >= Date.new(calendar_year, (max_month + 1), 1))

        false
      end

      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Metrics/CyclomaticComplexity
      # rubocop:enable Metrics/PerceivedComplexity
      # rubocop:enable Metrics/MethodLength

      def merge_and_validate_xmls(folder_count)
        folder_num = prepend_zeros(folder_count.to_s, 5)
        xml_merge = Generators::Reports::IrsXmlMerger.new("#{@h36_root_folder}/#{@h36_folder_name}", folder_num)
        xml_merge.irs_monthly_folder = @h36_root_folder
        xml_merge.process
        xml_merge.validate
      end

      def create_manifest(transmission_folder)
        Success(Generators::Reports::IrsMonthlyManifest.new.create(transmission_folder.to_s))
      end

      def create_new_irs_folder(folder_count)
        folder_number = prepend_zeros(folder_count.to_s, 3)
        @h36_folder_name = "IRS_H36_#{Time.now.strftime('%H_%M_%d_%m_%Y')}_#{folder_number}"
        create_directory "#{@h36_root_folder}/#{@h36_folder_name}"
      end

      def prepend_zeros(number, value)
        (value - number.to_s.size).times { number.prepend('0') }
        number
      end
    end
  end
end
# rubocop:enable Metrics/ClassLength
